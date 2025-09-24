class RenameStatutesToProvisions < ActiveRecord::Migration[8.0]
  def change
  rename_table :statutes, :provisions
  end
end
