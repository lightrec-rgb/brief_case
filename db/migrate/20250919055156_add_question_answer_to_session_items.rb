class AddQuestionAnswerToSessionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :session_items, :question, :text
    add_column :session_items, :answer,   :text
  end
end
