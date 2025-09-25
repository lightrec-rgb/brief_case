class CardTemplate < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # Kind of template, eg case or provision
  # ensure kind always contains a value - case or provision
  KINDS = %w[Case Provision].freeze
  validates :kind, presence: true, inclusion: { in: KINDS }

  # One-to-one relationship with a case or provision. Will delete the case or provision when deleted.
  # Use the appropriate model (case or provision)
  has_one :case_detail, class_name: "Case", dependent: :destroy, inverse_of: :card_template
  has_one :provision_detail, class_name: "Provision", dependent: :destroy, inverse_of: :card_template

  # Update the case or provision at the same time as card_template
  accepts_nested_attributes_for :case_detail
  accepts_nested_attributes_for :provision_detail

  # Returns templates for that user, that subject and that kind
  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :for_kind,    ->(k)       { where(kind: k) }

  # Method to build (in memory) a new card object linked to card_template / self
  def as_card
  Card.new(card_template: self)
  end
end
