class CreateSubjects < ActiveRecord::Migration[8.0]
  def change
    create_table :subjects do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.string :ancestry

      t.timestamps
    end
    add_index :subjects, :ancestry
  end
end
