class Card
  # === Lightweight wrapper around a card_template ===

  # Read card_template
  attr_reader :card_template

  # Constructor to give a card a template and store it
  def initialize(card_template:)
    @card_template = card_template
  end

  # Pass information to the template
  def user        = card_template.user
  def subject     = card_template.subject
  def kind        = card_template.kind

  # Give the card a display name
  def name        = card_template.name.presence || "#{subject&.name || 'Untitled'} - #{kind}"

  # Return the case or provision attached to the template
  def case_detail = card_template.case_detail
  def provision_detail = card_template.provision_detail

  # Build one question and answer pair for study sessions based on kind
  def build_pair
    case kind
    when "Case"    then CaseCard.new(self).build_pair
    when "Provision" then ProvisionCard.new(self).build_pair
    else
      { question: nil, answer: nil }
    end
  end
end
