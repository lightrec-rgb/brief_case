class CreateCards < ActiveRecord::Migration[8.0]
  def change
    create_table :cards do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :card_template, foreign_key: true

      t.string  :name, null: false
      t.string  :kind, null: false

      t.timestamps
    end

    add_index :cards, [:user_id, :subject_id, :kind]
    add_index :cards, [:user_id, :subject_id, :name], name: "idx_cards_user_subject_name"
  end
end