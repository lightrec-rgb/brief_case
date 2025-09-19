class CardTemplate < ApplicationRecord
  belongs_to :user
  belongs_to :subject

  # kind of template, eg case or statute
  validates :kind, presence: true, inclusion: { in: %w[Case] }

  # one-to-one relationship with case_detail. Will delete the case when deleted.
  # create and edit the case with card_template parameters in controllers
  has_one :case_detail, class_name: "Case", dependent: :destroy, inverse_of: :card_template
  accepts_nested_attributes_for :case_detail

  has_one :card, dependent: :destroy, inverse_of: :card_template
  after_create :create_blueprint!

  # filters by user, subject and kind (just case for now). Order by newest first.
  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :for_kind,    ->(k)       { where(kind: k) }
  scope :ordered,     ->          { order(id: :desc) }

  private

  def create_blueprint!
    Card.find_or_create_by!(card_template: self, user: user, subject: subject, kind: kind)
  end
end
