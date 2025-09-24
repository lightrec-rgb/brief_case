class AddFsrsFieldsToSessionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :session_items, :fsrs_card, :jsonb, default: {}, null: false
    add_column :session_items, :due_at, :datetime, precision: 6
    add_column :session_items, :last_review_at, :datetime, precision: 6
    add_column :session_items, :reps, :integer, default: 0, null: false
    add_column :session_items, :lapses, :integer, default: 0, null: false

    add_index :session_items, :due_at
  end
end
