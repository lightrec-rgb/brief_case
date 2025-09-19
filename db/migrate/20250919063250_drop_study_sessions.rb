class DropStudySessions < ActiveRecord::Migration[8.0]
  def change
    drop_table :study_sessions, if_exists: true
  end
end
