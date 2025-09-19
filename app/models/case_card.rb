class CaseCard < ApplicationRecord
  belongs_to :card, inverse_of: :case_card
  belongs_to :case, class_name: "Case"

  # take key details from card
  delegate :kind, :card_template, to: :card

  # ensure every casecard has a card, future-proofing
  validates :card, presence: true
  validate  :must_be_kind
  validate  :one_global_case, on: :create

  # one case_card for this user
  def self.shared
    first
  end

  # instructions for building a case card

  # Find a case via card_template - card relationship
  def source_case
    card_template&.case_detail
  end

  # create all possible question and answer pairs for the case in an array
  def candidates_for(our_case)
    return [] unless our_case
    titles = [ our_case.case_name, our_case.full_citation, our_case.case_short_name ]
               .compact
               .reject { |t| t.respond_to?(:blank?) ? t.blank? : t.to_s.strip.empty? }

    titles.flat_map do |t|
      [
        [ "What is the key principle in #{t}?",         our_case.key_principle ],
        [ "What are the material facts in #{t}?",       our_case.material_facts ],
        [ "What was the issue to be resolved in #{t}?", our_case.issue ]
      ]
    end
  end

  # prepare the question and answer for session_item
  def build_pair(our_case:)
    cands = candidates_for(our_case)
    return { question: nil, answer: nil } if cands.empty?
    q, a = cands.sample
    { question: q, answer: a }
  end

  private

  # ensure the parent card is of type case
  def must_be_kind
    errors.add(:card, "must be kind 'Case'") unless card&.kind == "Case"
  end

  def one_global_case
    if CaseCard.exists?
      errors.add(:base, "Only one CaseCard rules record is allowed")
    end
  end
end
