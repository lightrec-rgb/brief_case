class CreateCases < ActiveRecord::Migration[8.0]
  def change
    create_table :cases do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.references :card_templates, null: false, foreign_key: true
      t.string :full_citation
      t.string :case_name
      t.string :case_short_name
      t.text :material_facts
      t.text :issue
      t.text :key_principle

      t.timestamps
    end
  end
end
