# Code taken and adapted from FSRS (https://github.com/open-spaced-repetition/rb-fsrs/blob/master/lib/fsrs/fsrs.rb)
# needed for scheduling only (Again/Hard/Good/Easy)

module Fsrs
  # Rating constants
  class Rating
    AGAIN = 1
    HARD  = 2
    GOOD  = 3
    EASY  = 4
  end

  # Card state constants
  class State
    NEW        = 0
    LEARNING   = 1
    REVIEW     = 2
    RELEARNING = 3
  end

  # Tunable parameters (defaults work fine)
  class Parameters
    attr_accessor :request_retention, :maximum_interval, :w

    def initialize
      @request_retention = 0.9
      @maximum_interval  = 36_500
      @w = [ 0.4, 0.6, 2.4, 5.8, 4.93, 0.94, 0.86, 0.01, 1.49, 0.14, 0.94,
            2.18, 0.05, 0.34, 1.26, 0.29, 2.61 ]
    end
  end

  # The per-card memory state we persist on SessionItem (as JSON)
  class Card
    attr_accessor :due, :stability, :difficulty, :elapsed_days, :scheduled_days,
                  :reps, :lapses, :state, :last_review

    def initialize
      @due            = Time.at(0).utc # set by app on init
      @stability      = 0.0
      @difficulty     = 0.0
      @elapsed_days   = 0
      @scheduled_days = 0
      @reps           = 0
      @lapses         = 0
      @state          = State::NEW
      @last_review    = nil
    end

    def clone
      Marshal.load(Marshal.dump(self))
    end

    def to_h
      {
        state: @state,
        due: @due&.iso8601,
        stability: @stability,
        difficulty: @difficulty,
        elapsed_days: @elapsed_days,
        scheduled_days: @scheduled_days,
        reps: @reps,
        lapses: @lapses,
        last_review: @last_review&.iso8601
      }
    end

    def self.from_h(hash)
      c = new
      h = hash.transform_keys(&:to_sym)
      c.state          = h[:state].to_i
      c.due            = h[:due].present? ? Time.iso8601(h[:due]).utc : Time.at(0).utc
      c.stability      = h[:stability].to_f
      c.difficulty     = h[:difficulty].to_f
      c.elapsed_days   = h[:elapsed_days].to_i
      c.scheduled_days = h[:scheduled_days].to_i
      c.reps           = h[:reps].to_i
      c.lapses         = h[:lapses].to_i
      c.last_review    = h[:last_review].present? ? Time.iso8601(h[:last_review]).utc : nil
      c
    end
  end

  # Holds 4 possible next-card outcomes (again/hard/good/easy)
  class CardScheduler
    attr_accessor :again, :hard, :good, :easy

    def initialize(card)
      @again = card.clone
      @hard  = card.clone
      @good  = card.clone
      @easy  = card.clone
    end

    def update_state(state)
      case state
      when State::NEW
        @again.state = State::LEARNING
        @hard.state  = State::LEARNING
        @good.state  = State::LEARNING
        @easy.state  = State::REVIEW
      when State::LEARNING, State::RELEARNING
        @again.state = state
        @hard.state  = state
        @good.state  = State::REVIEW
        @easy.state  = State::REVIEW
      when State::REVIEW
        @again.state = State::RELEARNING
        @hard.state  = State::REVIEW
        @good.state  = State::REVIEW
        @easy.state  = State::REVIEW
        @again.lapses += 1
      end
    end

    def schedule(now, hard_days, good_days, easy_days)
      @again.scheduled_days = 0
      @hard.scheduled_days  = hard_days
      @good.scheduled_days  = good_days
      @easy.scheduled_days  = easy_days

      @again.due = now + 5.minutes
      @hard.due  = hard_days.positive? ? now + hard_days.days : now + 10.minutes
      @good.due  = now + good_days.days
      @easy.due  = now + easy_days.days
    end
  end

  # Computes next outcomes; we only expose `outcomes(card, now_utc)`
  class Scheduler
    attr_accessor :p, :decay, :factor

    def initialize
      @p     = Parameters.new
      @decay = -0.5
      @factor = (0.9**(1 / @decay)) - 1
    end

    # Returns a hash { 1=>Card, 2=>Card, 3=>Card, 4=>Card }
    def outcomes(card, now_utc)
      raise ArgumentError, "now must be UTC" unless now_utc.utc?

      c = card.clone
      c.elapsed_days = elapsed_days(c, now_utc)
      c.last_review  = now_utc
      c.reps        += 1

      cs = CardScheduler.new(c)
      cs.update_state(c.state)

      case c.state
      when State::NEW
        init_new(cs, now_utc)
      when State::LEARNING, State::RELEARNING
        schedule_learning(cs, now_utc)
      when State::REVIEW
        schedule_review(cs, c, now_utc)
      end

      {
        Rating::AGAIN => cs.again,
        Rating::HARD  => cs.hard,
        Rating::GOOD  => cs.good,
        Rating::EASY  => cs.easy
      }
    end

    private

    def elapsed_days(card, now)
      card.state == State::NEW || card.last_review.nil? ? 0 : ((now - card.last_review) / 86_400.0).floor
    end

    # ----- NEW state -----
    def init_new(cs, now)
      init_ds(cs)
      cs.again.due = now + 60
      cs.hard.due  = now + (5 * 60)
      cs.good.due  = now + (10 * 60)
      easy_days    = next_interval(cs.easy.stability)
      cs.easy.scheduled_days = easy_days
      cs.easy.due  = now + easy_days.days
    end

    def init_ds(cs)
      cs.again.difficulty = init_difficulty(Rating::AGAIN)
      cs.again.stability  = init_stability(Rating::AGAIN)
      cs.hard.difficulty  = init_difficulty(Rating::HARD)
      cs.hard.stability   = init_stability(Rating::HARD)
      cs.good.difficulty  = init_difficulty(Rating::GOOD)
      cs.good.stability   = init_stability(Rating::GOOD)
      cs.easy.difficulty  = init_difficulty(Rating::EASY)
      cs.easy.stability   = init_stability(Rating::EASY)
    end

    def init_stability(r)
      [ p.w[r - 1], 0.1 ].max
    end

    def init_difficulty(r)
      (p.w[4] - (p.w[5] * (r - 3))).clamp(1, 10)
    end

    # ----- LEARNING / RELEARNING -----
    def schedule_learning(cs, now)
      hard_days = 0
      good_days = next_interval(cs.good.stability)
      easy_days = [ next_interval(cs.easy.stability), good_days + 1 ].max
      cs.schedule(now, hard_days, good_days, easy_days)
    end

    # ----- REVIEW -----
    def schedule_review(cs, card, now)
      interval        = card.elapsed_days
      last_d, last_s  = card.difficulty, card.stability
      retrievability  = forgetting_curve(interval, last_s)
      update_next_ds(cs, last_d, last_s, retrievability)

      hard_days = next_interval(cs.hard.stability)
      good_days = next_interval(cs.good.stability)
      hard_days = [ hard_days, good_days ].min
      good_days = [ good_days, hard_days + 1 ].max
      easy_days = [ next_interval(cs.easy.stability), good_days + 1 ].max
      cs.schedule(now, hard_days, good_days, easy_days)
    end

    def forgetting_curve(elapsed_days, stability)
      (1 + (factor * elapsed_days / stability))**decay
    end

    def update_next_ds(cs, last_d, last_s, r)
      cs.again.difficulty = next_difficulty(last_d, Rating::AGAIN)
      cs.again.stability  = next_forget_stability(last_d, last_s, r)

      cs.hard.difficulty  = next_difficulty(last_d, Rating::HARD)
      cs.hard.stability   = next_recall_stability(last_d, last_s, r, Rating::HARD)

      cs.good.difficulty  = next_difficulty(last_d, Rating::GOOD)
      cs.good.stability   = next_recall_stability(last_d, last_s, r, Rating::GOOD)

      cs.easy.difficulty  = next_difficulty(last_d, Rating::EASY)
      cs.easy.stability   = next_recall_stability(last_d, last_s, r, Rating::EASY)
    end

    def next_difficulty(d, rating)
      next_d = d - (p.w[6] * (rating - 3))
      mean_reversion(p.w[4], next_d).clamp(1, 10)
    end

    def mean_reversion(init, current)
      (p.w[7] * init) + ((1 - p.w[7]) * current)
    end

    def next_recall_stability(d, s, r, rating)
      hard_penalty = rating == Rating::HARD ? p.w[15] : 1
      easy_bonus   = rating == Rating::EASY ? p.w[16] : 1
      s * (1 + (Math.exp(p.w[8]) * (11 - d) * (s**-p.w[9]) *
           (Math.exp((1 - r) * p.w[10]) - 1) * hard_penalty * easy_bonus))
    end

    def next_forget_stability(d, s, r)
      p.w[11] * (d**-p.w[12]) * (((s + 1)**p.w[13]) - 1) * Math.exp((1 - r) * p.w[14])
    end

    def next_interval(stability)
      ((stability / factor) * ((p.request_retention**(1 / decay)) - 1)).round.clamp(1, p.maximum_interval)
    end
  end
end
