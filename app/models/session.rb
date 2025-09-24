class Session < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # there will be many session_items to every session, ordered by position.
  # they will be deleted if the session is deleted
  has_many :session_items,
         -> { order(:position) },
         dependent: :destroy,
         class_name: "SessionItem",
         inverse_of: :session

  STATUSES = {
  draft:       "draft",
  in_progress: "in_progress",
  paused:      "paused",
  completed:   "completed" # kept for compatibility
  }.freeze

  enum :status, STATUSES, default: :draft
  validates :status, presence: true, inclusion: { in: STATUSES.keys.map(&:to_s) }

  before_validation :default_status, on: :create
  # a status allows the user to create a session but not start it, to start it,
  # to stop at some point and to continue, and to complete it

  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :recent,      ->          { order(created_at: :desc) }

  # create stages for a session so a user can leave and return to a session
  def start!
    transaction do
      update!(
        status: "in_progress",
        started_at: (started_at || Time.current),
        paused_at: nil
      )
      if current_pos.to_i < 1
        first_pending = session_items.where.not(state: "done").order(:position).first
        self.current_pos = first_pending&.position
      end
      save!
    end
  end

  def pause!
    update!(status: "paused", paused_at: Time.current)
  end

  def resume!
    update!(status: "in_progress", paused_at: nil)
  end

  # create the option for a user to reset the cards so they can start again
  def reset!
    transaction do
      # Reset each item's FSRS state and progress
      session_items.find_each(&:reset_fsrs!)

      # Recompute counters
      self.done_count  = 0
      self.total_count = session_items.count
      self.current_pos = 1
      self.status      = "in_progress"
      self.started_at  = (started_at || Time.current)
      self.paused_at   = nil
      self.completed_at = nil
      save!
    end
  end

  # Next item that is due now (or nil if none)
  def current_item
    return nil if total_count.to_i <= 0

    session_items
      .where("due_at IS NULL OR due_at <= ?", Time.current.utc)
      .order(Arel.sql("COALESCE(due_at, '1970-01-01') ASC"))
      .first
  end

  # Kept for compatibility; FSRS flow doesn’t use positional "next"
  def next_item
    session_items
      .where("due_at IS NULL OR due_at <= ?", Time.current.utc)
      .where("position > ?", (current_pos || 0))
      .order(:position)
      .first
  end

  def prepare_current_item!
    i = current_item
    return unless i

    if i.state == "pending"
      i.build_prompt! if i.respond_to?(:build_prompt!) && i.question.blank?
      i.started_at ||= Time.current
      i.save!
    end
    i
  end

  # counts for user feedback
  def new_count
  session_items
    .where("fsrs_card ->> 'state' = ?", Fsrs::State::NEW.to_s)
    .count
  end

  def due_count
    session_items
      .where("due_at IS NULL OR due_at <= ?", Time.current.utc)
      .count
  end

  def review_count
    session_items.to_a.count { |si|
      si.fsrs_card.present? &&
        si.fsrs_card["state"].to_i == Fsrs::State::REVIEW
    }
  end

  # New FSRS path: rate the current card (1: Again, 2: Hard, 3: Good, 4: Easy)
  # Session does not "complete"—it stays in_progress; items schedule themselves.
  def advance_with_rating!(rating)
    transaction do
      item = current_item
      return self unless item

      item.review!(rating) # schedules next due_at, updates reps/lapses

      # For list/progress UI: "done" = not due now
      self.done_count = session_items.where("due_at > ?", Time.current.utc).count
      self.status     = "in_progress"
      save!
    end
  end

  # Backwards compatibility: map correct/incorrect to FSRS ratings
  # correct: true  -> GOOD (3)
  # correct: false -> AGAIN (1)
  # correct: nil   -> GOOD (3) as a safe default
  def advance!(correct: nil)
    rating =
      case correct
      when true  then 3
      when false then 1
      else 3
      end
    advance_with_rating!(rating)
  end


  # -- Deck building ---------------------------------------------------------

  # Build a deck, assign positions, initialise counters.
  # (FSRS state initialises in SessionItem after_create)
  def build_from_items!(items:, shuffled: true, name: nil)
    raise ArgumentError, "There are no entries for this subject" if items.blank?

    transaction do
      # ensure the parent exists
      if new_record?
        self.status ||= "draft"
        save!
      end

      ordered = shuffled ? items.shuffle : items.to_a

      session_items.destroy_all
      ordered.each_with_index do |obj, idx|
        si = session_items.create!(
          item_type: obj.class.name,
          item_id:   obj.id,
          position:  idx + 1,
          state:     "pending"
        )
        si.build_prompt!
      end

      update!(
        name:         name || self.name,
        shuffled:     shuffled,
        total_count:  ordered.size,
        done_count:   0,
        current_pos:  ordered.size.positive? ? 1 : nil, # harmless with FSRS
        status:       "draft",
        started_at:   nil,
        paused_at:    nil,
        completed_at: nil
      )
    end

    self
  end

  private

  def default_status
    self.status ||= "draft"
  end
end
