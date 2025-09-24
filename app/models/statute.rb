class Statute < ApplicationRecord
  belongs_to :card_template, inverse_of: :statute_detail
  belongs_to :act, optional: true, inverse_of: :statutes

  validates :provision_ref, presence: true
  validates :act, presence: true, on: :create

  # When creating under an Act, copy the Act header into the statute fields
  before_validation :copy_act_header, on: :create

  private

  def copy_act_header
    return unless act
    self.act_name       ||= act.act_name
    self.act_short_name ||= act.act_short_name
    self.jurisdiction   ||= act.jurisdiction
    self.year           ||= act.year
  end
end