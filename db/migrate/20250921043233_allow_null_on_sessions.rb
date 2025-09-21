class AllowNullOnSessions < ActiveRecord::Migration[8.0]
  def change
    change_column :sessions, :current_pos, :integer, null: true
  end
end
