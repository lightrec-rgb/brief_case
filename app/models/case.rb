class Case < ApplicationRecord
  belongs_to :user
  belongs_to :subject
  belongs_to :card_templates
end
