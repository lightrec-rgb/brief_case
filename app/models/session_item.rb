class SessionItem < ApplicationRecord
  belongs_to :session, class_name: "Session", inverse_of: :session_items

  # allow session_item to point to a card type such as casecard
  belongs_to :item, polymorphic: true
  
  STATES = {
    pending: "pending",
    seen:    "seen",
    done:    "done"
  }.freeze

  enum :state, STATES
   # restrict a card to three states - not yet done, in progress and done.
  validates :state, presence: true, inclusion: { in: STATES.keys.map(&:to_s) }

  # create association with subject and user
  delegate :user, :subject, to: :item, allow_nil: true

  # mark the card as in progress, maybe seen so as not to confuse with session
  def mark_seen!
    update!(
      state: "seen", 
      started_at: (started_at || Time.current)
    )
  end
  
  # mark the card as complete
  def mark_done!(correct: nil)
    update!(
      state: "done", 
      correct: correct, 
      completed_at: Time.current,
      started_at: (started_at || Time.current))
  end

  def build_prompt!
    return self unless question.blank? && answer.blank?

    rules  = CaseCard.shared
    source = item&.card_template&.case_detail
    return self unless rules && source

    pair = rules.build_pair(our_case: source)
    update!(question: pair[:question], answer: pair[:answer])
    self
  end
end