class Card < ApplicationRecord
  
  belongs_to :user
  belongs_to :subject
  belongs_to :card_template, inverse_of: :card

  has_one :case_card, dependent: :destroy, inverse_of: :card

  # card is the parent of types of cards, for now just case. 
  # validate kind and card_template
  validates :card_template, presence: true
  validates :kind, presence: true, inclusion: { in: %w[Case] }


  # pull information from card_template (user, subject, case)
  before_validation :inherit_from_template, on: :create

  # save information from card_template
  after_create :copy_kind!

  scope :owned_by,    ->(user)    { where(user:) }
  scope :for_subject, ->(subject) { where(subject:) }
  scope :for_kind,    ->(k)       { where(kind: k) }
  scope :ordered,     ->          { order(created_at: :desc) }

  private

  # method to pull information from card_tenmplate
  def inherit_from_template
    t = card_template or return

    self.user    ||= t.user
    self.subject ||= t.subject
    self.kind    ||= t.kind

    self.name ||= t.name.presence || "#{t.subject.name} - #{t.kind}"
  end

  # method to save information from card_template
  def copy_kind!
    true
  end
end