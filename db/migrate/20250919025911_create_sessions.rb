class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.references :user,    null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true

      t.string  :name
      t.string  :status, null: false
      t.integer :total_count, null: false, default: 0
      t.integer :done_count,  null: false, default: 0
      t.integer :current_pos, null: false, default: 1

      t.datetime :started_at
      t.datetime :paused_at
      t.datetime :completed_at

      t.boolean :shuffled, null: false, default: true
      t.integer :shuffle_seed

      t.timestamps
    end

    add_index :sessions, [:user_id, :subject_id]
    add_index :sessions, :status
  end
end
