class Card
  attr_reader :card_template

  def initialize(card_template:)
    @card_template = card_template
  end

  # Inherit information from card_template
  def user        = card_template.user
  def subject     = card_template.subject
  def kind        = card_template.kind
  def name        = card_template.name.presence || "#{subject&.name || 'Untitled'} - #{kind}"
 
  def case_detail = card_template.case_detail
  def statute_detail = card_template.statute_detail

  # Rules for strategy
  def build_pair
    case kind
    when "Case"    then CaseCard.new(self).build_pair
    when "Statute" then StatuteCard.new(self).build_pair
    else
      { question: nil, answer: nil }
    end
  end
end
