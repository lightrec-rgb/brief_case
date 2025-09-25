class SessionItem < ApplicationRecord
  belongs_to :session, class_name: "Session", inverse_of: :session_items

  # Polymorphic association - each session_item can point to different models
  # Currently card_template
  belongs_to :item, polymorphic: true

  # Lifecycle states of a session_item (actual card)
  STATES = {
    pending: "pending",
    seen:    "seen",
    done:    "done"
  }.freeze

  # Enum for states / lifecycle states
  # Ensures state is present and valid
  enum :state, STATES, default: :pending
  validates :state, presence: true, inclusion: { in: STATES.keys.map(&:to_s) }

  # Add shortcut method to forward to an item
  delegate :user, :subject, to: :item, allow_nil: true

  # After a session is created, initialise FSRS fields
  after_create :init_fsrs_card!

  # === Prompt Building (content for front and back of cards) ===

  # Method to create the question / answer text for the item
  # Only runs when an item is a card_template and is blank
  # Ask card_template (wrapped as a card) to create q&a pair
  # Save the q&a to the db and return self to call another method on item
  def build_prompt!
    return self unless question.blank? && answer.blank?
    return self unless item.is_a?(CardTemplate)

    pair = item.as_card.build_pair
    return self unless pair[:question].present? && pair[:answer].present?

    update!(question: pair[:question], answer: pair[:answer])
    self
  end

  # === FSRS review flow ===
  # Code taken and adapted from FSRS
  # (https://github.com/open-spaced-repetition/rb-fsrs/blob/master/lib/fsrs/fsrs.rb)

  # Rate the card using FSRS and schedule the next review
  # Read time now, read existing FSRS data, build an FSRS card and create the scheduler
  # Identify the plan that matches a user's rating
  # Save the plan to the db
  def review!(rating)
    now = Time.current.utc

    card_hash = ensure_hash(fsrs_card)
    card      = card_hash.present? ? Fsrs::Card.from_h(card_hash) : Fsrs::Card.new
    scheduler = Fsrs::Scheduler.new

    logs = scheduler.repeat(card, now)
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

  # Preview the next due time for each rating without saving
  # Load / Create the FSRS card and run FSRS to get schedules for each rating
  # Return predicted due_at and scheduled_days
  # If it fails, return a fallback so UI still shows something
  def preview_options(now: Time.current.utc)
    data = ensure_hash(fsrs_card)
    base_card = data.present? ? Fsrs::Card.from_h(data) : Fsrs::Card.new

    scheduler = Fsrs::Scheduler.new
    logs = scheduler.repeat(base_card, now.utc)

    logs.transform_values do |sched|
      c = sched.card
      { due_at: to_time(c.due), scheduled_days: c.scheduled_days }
    end
  rescue => e
    Rails.logger.warn("[FSRS preview_options] #{e.class}: #{e.message}")
    {
      1 => { due_at: 5.minutes.from_now,  scheduled_days: 0 },
      2 => { due_at: 10.minutes.from_now, scheduled_days: 0 },
      3 => { due_at: 1.day.from_now,      scheduled_days: 1 },
      4 => { due_at: 3.days.from_now,     scheduled_days: 3 }
    }
  end

  # Read FSRS state as an integer (whether fsrs_card is a Hash or JSON String)
  def fsrs_state_i
    data =
      case fsrs_card
      when Hash   then fsrs_card
      when String then (JSON.parse(fsrs_card) rescue {})
      else {}
      end

    (data["state"] || data[:state]).to_i
  end

  # === Legacy session states ===

  # Mark an item as seen (unless done)
  # Note - legacy, replaced by FSRS
  def mark_seen!
    return if done?
    update!(state: :seen, started_at: (started_at || Time.current))
  end

  # Mark and item as done, whether answer was correct and timestamp completion
  # Note - legacy, replaced by FSRS
  def mark_done!(correct: nil)
    update!(
      state: "done",
      correct: correct,
      completed_at: Time.current,
      started_at: (started_at || Time.current)
    )
  end

  # === Reset and Initialisation ===

  # Reset an item's FSRS state to New (and due now)
  # Clear metrics and lifecycle fields so the card can be studied from scratch
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

  private

  # Turn fsrs_card into a Hash (supports Hash or JSON String).
  def ensure_hash(value)
    h =
      case value
      when Hash   then value
      when String then (JSON.parse(value) rescue {})
      else {}
      end
    h.deep_symbolize_keys
  end

  # Make all date/time format a time object.
  def to_time(dt_like)
    case dt_like
    when Time     then dt_like
    when DateTime then dt_like.to_time
    else
      Time.zone.parse(dt_like.to_s) rescue Time.current
    end
  end

  # Initialises the FSRS state for a session_item
  # Sets default paramaters and persists initial state to the db
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
