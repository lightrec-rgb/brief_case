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
  completed:   "completed"
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
      session_items.update_all(
        state: "pending",
        correct: nil,
        started_at: nil,
        completed_at: nil
      )
      update!(
        done_count: 0,
        current_pos: 1,
        status: "in_progress",
        started_at: (started_at || Time.current),
        paused_at: nil,
        completed_at: nil
      )
    end
  end

  def current_item
    return nil if total_count.to_i <= 0
    session_items.find_by(position: current_pos) ||
      session_items.where.not(state: "done").order(:position).first
  end

  def next_item
    session_items.where("position > ?", (current_pos || 0))
                 .where.not(state: "done")
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

  # track when a user has completed a session
  def advance!(correct: nil)
    transaction do
      return self if status == "completed"

      item = current_item
      return self unless item

      item.mark_done!(correct: correct)

      self.done_count  = session_items.where(state: "done").count

      if (ni = next_item)
        self.current_pos = ni.position
        self.status      = "in_progress"
        save!
      else
          self.current_pos = nil
          update!(
            status:       "completed",
            completed_at: Time.current,
            done_count:   total_count.to_i
          )
      end
    end
  end


  # build a deck, assign card positions, and initialise a counter.
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
      session_items.create!(
        item_type: obj.class.name,
        item_id:   obj.id,
        position:  idx + 1,
        state:     "pending"
      )
    end

    update!(
      name:        name || self.name,
      shuffled:    shuffled,
      total_count: ordered.size,
      done_count:  0,
      current_pos: ordered.size.positive? ? 1 : nil,
      status:      "draft",
      started_at:  nil,
      paused_at:   nil,
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
