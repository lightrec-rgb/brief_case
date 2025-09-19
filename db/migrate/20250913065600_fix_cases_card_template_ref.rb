class FixCasesCardTemplateRef < ActiveRecord::Migration[8.0]
  def up
    # 1) Rename the column to what Rails expects
    rename_column :cases, :card_templates_id, :card_template_id

    # 2) Recreate the foreign key (in case it was created with the old name)
    # Remove old FK if it exists
    begin
      remove_foreign_key :cases, :card_templates
    rescue StandardError
      # ignore if it didn't exist
    end

    # Add FK on the correctly named column
    add_foreign_key :cases, :card_templates, column: :card_template_id

    # 3) Ensure index exists on the correct column
    add_index :cases, :card_template_id unless index_exists?(:cases, :card_template_id)
  end

  def down
    # reverse (optional)
    remove_index :cases, :card_template_id if index_exists?(:cases, :card_template_id)
    begin
      remove_foreign_key :cases, column: :card_template_id
    rescue StandardError
    end
    rename_column :cases, :card_template_id, :card_templates_id
    add_foreign_key :cases, :card_templates, column: :card_templates_id
  end
end
