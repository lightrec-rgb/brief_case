class AddStatusBeforeCompleteToSessions < ActiveRecord::Migration[8.0]
  def change
    add_column :sessions, :status_before_complete, :string
    add_index  :sessions, :status_before_complete
  end
end
