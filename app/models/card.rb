class Card 

  attr_reader :card_template

  def initialize(card_template:)
    @card_template = card_template
  end

  # Inherit information from card_template and case
  def user        = card_template.user
  def subject     = card_template.subject
  def kind        = card_template.kind || "Case"
  def name        = card_template.name.presence || "#{subject&.name || 'Untitled'} - #{kind}"
  def case_detail = card_template.case_detail

  # Rules
  def build_pair
    CaseCard.new(self).build_pair
  end
end