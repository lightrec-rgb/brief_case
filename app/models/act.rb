class Act < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  has_many :statutes, dependent: :restrict_with_error

  validates :act_name, presence: true
  validates :year, numericality: { only_integer: true }, allow_nil: true

  def display_name
    [act_short_name.presence || act_name, year, jurisdiction].compact.join(" ")
  end
end