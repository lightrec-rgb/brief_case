class AddSubjectstoSavedActs < ActiveRecord::Migration[8.0]
  def change
    add_reference :saved_acts, :subject, foreign_key: true, null: true

    # replace your old unique index so subject is part of the key
    remove_index :saved_acts, name: :index_saved_acts_on_user_and_act, if_exists: true
    execute <<~SQL
      CREATE UNIQUE INDEX index_saved_acts_on_user_act_norm_year_subject
      ON saved_acts (
        user_id,
        lower(act_name),
        lower(COALESCE(jurisdiction, '')),
        COALESCE(year, 0),
        COALESCE(subject_id, 0)
      );
    SQL
  end
end
