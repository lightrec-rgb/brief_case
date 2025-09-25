class Session < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # A one-to-many relationship (one session, many session_items)
  # Oredered by position
  # Session_items deleted if the session is deleted
  has_many :session_items,
         -> { order(:position) },
         dependent: :destroy,
         class_name: "SessionItem",
         inverse_of: :session

  # Lifecycle stages of a session
  STATUSES = {
  draft:       "draft",
  in_progress: "in_progress",
  paused:      "paused",
  completed:   "completed"
  }.freeze

  # Enum for status / lifecycle stages
  # Ensures status is present and valid
  enum :status, STATUSES, default: :draft
  validates :status, presence: true, inclusion: { in: STATUSES.keys.map(&:to_s) }

  #
  before_validation :default_status, on: :create

  # Returns sessions for that user, that subject and ordered by recent
  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :recent,      ->          { order(created_at: :desc) }


  # === Lifecycle / Session progress ===

  # Begin a study session in db, set to in_progress
  # If current position is not set, find the first 'not done' item and set it
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

  # Pause the session and time-stamp the pause
  # Note - now largely redundant with FSRS implementation
  def pause!
    update!(status: "paused", paused_at: Time.current)
  end

  # Resume a session
  def resume!
    update!(status: "in_progress", paused_at: nil)
  end

  # Clear progress on a session and set it back to draft status
  # Reset each session_item's FSRS state and progress
  def reset!
    transaction do
      session_items.find_each(&:reset_fsrs!)

      self.done_count  = 0
      self.total_count = session_items.count
      self.current_pos = nil
      self.status      = "draft"
      self.started_at  = nil
      self.paused_at   = nil
      self.completed_at = nil
      save!
    end
  end

  # Mark a session as finished (now outside the FSRS process)
  def complete!
    update!(status: "completed", completed_at: Time.current, paused_at: nil)
  end

  # === Deck building ===

  # Initialise a session, ensruing the it has items and the session record exists
  # Shuffles the items
  # Clears existing items and creates a session item for each object
  # Assigns a position, sets state as pending and pre-builds the prompt for each session_item
  # Updates sesssion data
  def build_from_items!(items:, shuffled: true, name: nil)
    raise ArgumentError, "There are no entries for this subject" if items.blank?

    transaction do
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
        current_pos:  ordered.size.positive? ? 1 : nil,
        status:       "draft",
        started_at:   nil,
        paused_at:    nil,
        completed_at: nil
      )
    end

    self
  end

  # === Item selection ===

  # Determines the item to study now (for non-complete status)
  # Due now if never studied and not scheduled in the future
  # Ordered so the oldest appears first
  def current_item
    return nil if total_count.to_i <= 0
    return nil if status == "completed"

    session_items
      .where("due_at IS NULL OR due_at <= ?", Time.current.utc)
      .order(Arel.sql("COALESCE(due_at, '1970-01-01') ASC"))
      .first
  end

  # Identify the next item to study
  # Note - redundant with FSRS implementation
  def next_item
    session_items
      .where("due_at IS NULL OR due_at <= ?", Time.current.utc)
      .where("position > ?", (current_pos || 0))
      .order(:position)
      .first
  end

  # Gets the current item
  def prepare_current_item!
    return nil if status == "completed"
    i = current_item
    return unless i

    if i.state == "pending"
      i.build_prompt! if i.respond_to?(:build_prompt!) && i.question.blank?
      i.started_at ||= Time.current
      i.save!
    end
    i
  end

  # === FSRS Integration ===
  # Code taken and adapted from FSRS
  # (https://github.com/open-spaced-repetition/rb-fsrs/blob/master/lib/fsrs/fsrs.rb)

  # Hadles a user's rating for the current card (Again / Hard / Good / Easy)
  # Applies logic from FSRS on the current item, including due_at and repititions
  # Recounts items not due (done)
  def advance_with_rating!(rating)
    return self if status == "completed"
    transaction do
      item = current_item
      return self unless item

      item.review!(rating)

      self.done_count = session_items.where("due_at > ?", Time.current.utc).count
      self.status     = "in_progress"
      save!
    end
  end

  # === Progress metrics ===

  # Counts all the items in "New" FSRS state
  def new_count
    session_items.to_a.count { |si|
      si.fsrs_card.present? && si.fsrs_card["state"].to_i == Fsrs::State::NEW
    }
  end

  # Counts all the items in "Due Now" FSRS state, excluding New cards
  def due_count
    now = Time.current.utc
    session_items.to_a.count { |si|
      (si.due_at.nil? || si.due_at <= now) &&
        si.fsrs_state_i != Fsrs::State::NEW
    }
  end

  # Counts all the items in "Review" FSRS state
  def review_count
    session_items.to_a.count { |si|
      si.fsrs_card.present? && si.fsrs_card["state"].to_i == Fsrs::State::REVIEW
    }
  end

  private

  # Set a default status on create
  def default_status
    self.status ||= "draft"
  end
end
