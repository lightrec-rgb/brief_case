class DeleteCardsAndCaseCardTables < ActiveRecord::Migration[8.0]
  def change
    drop_table :case_cards, if_exists: true
    drop_table :cards, if_exists: true
  end
end
