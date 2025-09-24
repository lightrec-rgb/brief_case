class CreateActsAndLinkStatutes < ActiveRecord::Migration[8.0]
  def change
    create_table :acts do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.string  :act_name,       null: false
      t.string  :act_short_name
      t.string  :jurisdiction
      t.integer :year
      t.timestamps
    end

    # Link statutes to acts (provisions belong to an Act)
    add_reference :statutes, :act, foreign_key: true, null: true

    # Index to keep names tidy per user/subject
    add_index :acts, [ :user_id, :subject_id, :act_name, :jurisdiction, :year ],
              unique: true,
              name: :index_acts_unique_in_subject
  end
end
