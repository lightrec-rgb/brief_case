class CreateStatutes < ActiveRecord::Migration[8.0]
  def change
    create_table :statutes do |t|
      # 1–1 with CardTemplate (mirror Cases/CardTemplate link)
      t.references :card_template,
                   null: false,
                   foreign_key: { to_table: :card_templates, on_delete: :cascade },
                   index: { unique: true }

      t.string :act_name,      null: false          
      t.string :act_short_name                       
      t.string :jurisdiction                          
      t.string :year                                   
      t.string :provision_ref, null: false           

      t.text   :provision_text                         

      t.timestamps
    end
  end
end
