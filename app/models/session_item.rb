class SessionItem < ApplicationRecord
  belongs_to :session, class_name: "Session", inverse_of: :session_items
  belongs_to :item, polymorphic: true

  STATES = {
    pending: "pending",
    seen:    "seen",
    done:    "done"
  }.freeze
  enum :state, STATES, default: :pending

  validates :state, presence: true, inclusion: { in: STATES.keys.map(&:to_s) }

  delegate :user, :subject, to: :item, allow_nil: true

  after_create :init_fsrs_card!

  # Build the front/back content from the underlying CardTemplate.
  def build_prompt!
    return self unless question.blank? && answer.blank?
    return self unless item.is_a?(CardTemplate)

    pair = item.as_card.build_pair
    return self unless pair[:question].present? && pair[:answer].present?

    update!(question: pair[:question], answer: pair[:answer])
    self
  end

  # === FSRS review flow ===
  # rating: 1=Again, 2=Hard, 3=Good, 4=Easy
  def review!(rating)
    now = Time.current.utc

    card_hash = ensure_hash(fsrs_card)
    card      = card_hash.present? ? Fsrs::Card.from_h(card_hash) : Fsrs::Card.new
    scheduler = Fsrs::Scheduler.new

    logs = scheduler.repeat(card, now) # => {1=>SchedulingInfo, 2=>..., 3=>..., 4=>...}
    info = logs[rating.to_i] || logs[Fsrs::Rating::GOOD]
    new_card = info.card

    due_time = to_time(new_card.due)

    update!(
      fsrs_card:      new_card.to_h,
      due_at:         due_time,
      last_review_at: now,
      reps:           new_card.reps,
      lapses:         new_card.lapses,
      state:          "seen",
      started_at:     (started_at || now)
    )
  end

  # Preview the next due time for each rating without saving.
  # Returns { 1=>{due_at: Time, scheduled_days: Integer}, 2=>..., 3=>..., 4=>... }
  def preview_options(now: Time.current.utc)
    data = ensure_hash(fsrs_card)
    base_card = data.present? ? Fsrs::Card.from_h(data) : Fsrs::Card.new

    scheduler = Fsrs::Scheduler.new
    logs = scheduler.repeat(base_card, now.utc) # rating => Fsrs::SchedulingInfo

    logs.transform_values do |sched|
      c = sched.card
      { due_at: to_time(c.due), scheduled_days: c.scheduled_days }
    end
  rescue => e
    Rails.logger.warn("[FSRS preview_options] #{e.class}: #{e.message}")
    # Fallback so UI never shows '—'
    {
      1 => { due_at: 5.minutes.from_now,  scheduled_days: 0 },
      2 => { due_at: 10.minutes.from_now, scheduled_days: 0 },
      3 => { due_at: 1.day.from_now,      scheduled_days: 1 },
      4 => { due_at: 3.days.from_now,     scheduled_days: 3 }
    }
  end

  # Used by Session#reset!
  def reset_fsrs!
    c = Fsrs::Card.new
    c.due = Time.current.utc.to_datetime
    update!(
      fsrs_card:      c.to_h,
      due_at:         c.due.to_time,
      last_review_at: nil,
      reps:           0,
      lapses:         0,
      state:          "pending",
      started_at:     nil,
      completed_at:   nil,
      correct:        nil
    )
  end

  # Legacy helpers
  def mark_seen!
    return if done?
    update!(state: :seen, started_at: (started_at || Time.current))
  end

  def mark_done!(correct: nil)
    update!(
      state: "done",
      correct: correct,
      completed_at: Time.current,
      started_at: (started_at || Time.current)
    )
  end

  private

  # Parse fsrs_card into a Hash (supports Hash or JSON String).
  def ensure_hash(value)
    h =
      case value
      when Hash   then value
      when String then (JSON.parse(value) rescue {})
      else {}
      end
    h.deep_symbolize_keys
  end

  def to_time(dt_like)
    case dt_like
    when Time     then dt_like
    when DateTime then dt_like.to_time
    else
      Time.zone.parse(dt_like.to_s) rescue Time.current
    end
  end

  def init_fsrs_card!
    return if fsrs_card.present?

    c = Fsrs::Card.new
    c.due = Time.current.utc.to_datetime
    update!(
      fsrs_card:      c.to_h,
      due_at:         c.due.to_time,
      last_review_at: nil,
      reps:           0,
      lapses:         0
    )
  end
end
