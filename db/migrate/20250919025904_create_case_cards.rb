class CreateCaseCards < ActiveRecord::Migration[8.0]
  def change
    create_table :case_cards do |t|
      t.references :card, null: false, foreign_key: true, index: { unique: true }
      t.references :case, null: false, foreign_key: true

      t.text :question
      t.text :answer

      t.timestamps
    end
  end
end