class Subject < ApplicationRecord
  belongs_to :user

  # due to ancestry, a subject can't be deleted until underlying children are:
  has_ancestry orphan_strategy: :restrict

  # a subject can have many card_templates and cannot be deleted until card_templates are
  has_many :card_templates, dependent: :restrict_with_error

  # must have a name, which must be unique within a user and a ancestry hierarchy
  validates :name, presence: true,
                   uniqueness: { scope: [:user_id, :ancestry], case_sensitive: false }

  # include subjects only for this user.
  scope :owned_by, ->(user) { where(user:) }

  # arrange subjects in alphabetical order 
  scope :alphabetical, -> { order(:name) }
  def self.tree_for(user)
    user.subjects.arrange
  end
  
end
