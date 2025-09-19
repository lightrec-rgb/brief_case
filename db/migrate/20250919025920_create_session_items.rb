class CreateSessionItems < ActiveRecord::Migration[8.0]
  def change
    create_table :session_items do |t|
      t.references :session, null: false, foreign_key: true

      # polymorphic: can point to Card, CaseCard, or future types
      t.string  :item_type, null: false
      t.bigint  :item_id,   null: false

      t.integer :position,  null: false
      t.string  :state,     null: false
      t.boolean :correct
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :session_items, [:session_id, :position], unique: true
    add_index :session_items, [:item_type, :item_id]
  end
end
