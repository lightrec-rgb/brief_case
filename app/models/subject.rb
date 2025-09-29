class Subject < ApplicationRecord
  belongs_to :user

  # Due to ancestry, a subject can't be deleted until underlying children are
  has_ancestry orphan_strategy: :restrict

  # Acts live under a subject and so can't delete if there are still acts
  has_many :acts, dependent: :restrict_with_error
  
  # A subject can have many card_templates and cannot be deleted until card_templates are
  has_many :card_templates, dependent: :destroy

  # Must have a name, which must be unique within a user and a ancestry hierarchy
  validates :name, presence: true,
                   uniqueness: { scope: [ :user_id, :ancestry ], case_sensitive: false }

  # Include subjects only for this user.
  scope :owned_by, ->(user) { where(user:) }

  # Arrange subjects in alphabetical order
  scope :alphabetical, -> { order(:name) }

  def self.tree_for(user)
    user.subjects.arrange
  end
end
