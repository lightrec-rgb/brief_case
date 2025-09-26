class Provision < ApplicationRecord
  belongs_to :card_template, inverse_of: :provision_detail
  belongs_to :act, optional: true

  # Must have a reference (section reference in legislation)
  # and must have text of the provision and optional summary
  # and must be linked to an Act when created
  validates :provision_ref, presence: true
  validates :provision_text, presence: true
  validates :summary, length: { maximum: 255 }, allow_blank: true
  validates :act, presence: true, on: :create

  # When creating a provision, copy the Act's header into the provision fields
  before_validation :copy_act_header, on: :create

  private

  # Method to clean up case information
  def copy_act_header
    return unless act
    self.act_name       ||= act.act_name
    self.act_short_name ||= act.act_short_name
    self.jurisdiction   ||= act.jurisdiction
    self.year           ||= act.year
  end
end
