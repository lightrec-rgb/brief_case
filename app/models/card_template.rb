class CardTemplate < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # kind of template, eg case or provision
  KINDS = %w[Case Provision].freeze
  validates :kind, presence: true, inclusion: { in: KINDS }

  # one-to-one relationship with case_detail. Will delete the case when deleted.
  # create and edit the case with card_template parameters in controllers
  has_one :case_detail, class_name: "Case", dependent: :destroy, inverse_of: :card_template
  has_one :provision_detail, class_name: "Provision", dependent: :destroy, inverse_of: :card_template

  accepts_nested_attributes_for :case_detail
  accepts_nested_attributes_for :provision_detail

  # filters by user, subject and kind (just case for now). Order by newest first.
  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :for_kind,    ->(k)       { where(kind: k) }

  # strategy for templates
  def as_card
  Card.new(card_template: self)
  end
end
