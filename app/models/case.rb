class Case < ApplicationRecord
 
  belongs_to :card_template, inverse_of: :case_detail
  belongs_to :user
  belongs_to :subject

  # must have a name, which must be unique within a user and for subject and card_template
  validates :case_name, presence: true
  validates :card_template, :user, :subject, presence: true

  # working with court cases, tidy up the input before validating it
  before_validation :strip_fields
  # when a case is created, inherit user and subject from the associated card_template
  before_validation :inherit_user_and_subject, on: :create

  # order cases alphabetically when queried
  scope :alphabetical, -> { order(:case_name) }

  private

  # method to clean up case information
  def strip_fields
    self.case_name       = case_name&.strip
    self.case_short_name = case_short_name&.strip
    self.full_citation   = full_citation&.strip
  end

  # method to inherit user and subject from the card_template
  def inherit_user_and_subject
    self.user    ||= card_template&.user
    self.subject ||= card_template&.subject
  end
end

