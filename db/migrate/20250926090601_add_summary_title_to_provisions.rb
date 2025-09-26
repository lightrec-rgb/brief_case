class AddSummaryTitleToProvisions < ActiveRecord::Migration[8.0]
  def change
    add_column :provisions, :summary, :string
  end
end
