class DropSavedActs < ActiveRecord::Migration[8.0]
  def change
    drop_table :saved_acts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subject, foreign_key: true
      t.string :act_name, null: false
      t.string :act_short_name
      t.string :jurisdiction
      t.integer :year
      t.timestamps
    end
  end
end
