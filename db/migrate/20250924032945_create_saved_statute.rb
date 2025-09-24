class CreateSavedStatute < ActiveRecord::Migration[8.0]
  def change
    create_table :saved_acts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :act_name, null: false
      t.string :act_short_name
      t.string :jurisdiction
      t.string :year
      t.timestamps
    end

    add_index :saved_acts,
              [ :user_id, :act_name, :jurisdiction, :year ],
              unique: true,
              name: "index_saved_acts_on_user_and_act"
  end
end
