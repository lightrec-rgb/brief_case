class CreateCardTemplates < ActiveRecord::Migration[8.0]
  def change
    create_table :card_templates do |t|
      t.references :user, null: false, foreign_key: true
      t.references :subject, null: false, foreign_key: true
      t.string :name
      t.string :kind

      t.timestamps
    end
  end
end
