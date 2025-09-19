class DefaultDraftOnSessionStatus < ActiveRecord::Migration[8.0]
  def up
    change_column_default :sessions, :status, "draft"
    execute <<~SQL
      UPDATE sessions SET status = 'draft' WHERE status IS NULL;
    SQL
  end

  def down
    change_column_default :sessions, :status, nil
  end
end
