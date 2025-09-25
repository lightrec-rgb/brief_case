class Act < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # Acts can contain many provisions. An Act can't be deleted until it's provisions are
  has_many :provisions, dependent: :restrict_with_error

  # Must have a name and the year can only be a number / integer
  validates :act_name, presence: true
  validates :year, numericality: { only_integer: true }, allow_nil: true

  # Display the Act's short name concatenate with year and jursidction where available
  # Second preference to use the act's full name
  def display_name
    if act_short_name.present?
      [act_short_name, year, jurisdiction].compact.join(" ")
    else
      act_name
  end
end
