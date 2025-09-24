# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_24_075603) do
  create_table "acts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.string "act_name", null: false
    t.string "act_short_name"
    t.string "jurisdiction"
    t.integer "year"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_acts_on_subject_id"
    t.index ["user_id", "subject_id", "act_name", "jurisdiction", "year"], name: "index_acts_unique_in_subject", unique: true
    t.index ["user_id"], name: "index_acts_on_user_id"
  end

  create_table "card_templates", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.string "name"
    t.string "kind"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["subject_id"], name: "index_card_templates_on_subject_id"
    t.index ["user_id"], name: "index_card_templates_on_user_id"
  end

  create_table "cases", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.integer "card_template_id", null: false
    t.string "full_citation"
    t.string "case_name"
    t.string "case_short_name"
    t.text "material_facts"
    t.text "issue"
    t.text "key_principle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_template_id"], name: "index_cases_on_card_template_id"
    t.index ["subject_id"], name: "index_cases_on_subject_id"
    t.index ["user_id"], name: "index_cases_on_user_id"
  end

  create_table "provisions", force: :cascade do |t|
    t.integer "card_template_id", null: false
    t.string "act_name", null: false
    t.string "act_short_name"
    t.string "jurisdiction"
    t.string "year"
    t.string "provision_ref", null: false
    t.text "provision_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "act_id"
    t.index ["act_id"], name: "index_provisions_on_act_id"
    t.index ["card_template_id"], name: "index_provisions_on_card_template_id", unique: true
  end

  create_table "session_items", force: :cascade do |t|
    t.integer "session_id", null: false
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.integer "position", null: false
    t.string "state", null: false
    t.boolean "correct"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "question"
    t.text "answer"
    t.json "fsrs_card", default: {}, null: false
    t.datetime "due_at"
    t.datetime "last_review_at"
    t.integer "reps", default: 0, null: false
    t.integer "lapses", default: 0, null: false
    t.index ["due_at"], name: "index_session_items_on_due_at"
    t.index ["item_type", "item_id"], name: "index_session_items_on_item_type_and_item_id"
    t.index ["session_id", "position"], name: "index_session_items_on_session_id_and_position", unique: true
    t.index ["session_id"], name: "index_session_items_on_session_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "subject_id", null: false
    t.string "name"
    t.string "status", default: "draft", null: false
    t.integer "total_count", default: 0, null: false
    t.integer "done_count", default: 0, null: false
    t.integer "current_pos"
    t.datetime "started_at"
    t.datetime "paused_at"
    t.datetime "completed_at"
    t.boolean "shuffled", default: true, null: false
    t.integer "shuffle_seed"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_sessions_on_status"
    t.index ["subject_id"], name: "index_sessions_on_subject_id"
    t.index ["user_id", "subject_id"], name: "index_sessions_on_user_id_and_subject_id"
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "subjects", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "name"
    t.string "ancestry"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ancestry"], name: "index_subjects_on_ancestry"
    t.index ["user_id"], name: "index_subjects_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "provider"
    t.string "uid"
    t.string "avatar_url"
    t.string "name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "acts", "subjects"
  add_foreign_key "acts", "users"
  add_foreign_key "card_templates", "subjects"
  add_foreign_key "card_templates", "users"
  add_foreign_key "cases", "card_templates"
  add_foreign_key "cases", "subjects"
  add_foreign_key "cases", "users"
  add_foreign_key "provisions", "acts"
  add_foreign_key "provisions", "card_templates", on_delete: :cascade
  add_foreign_key "session_items", "sessions"
  add_foreign_key "sessions", "subjects"
  add_foreign_key "sessions", "users"
  add_foreign_key "subjects", "users"
end
