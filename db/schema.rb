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

ActiveRecord::Schema[8.0].define(version: 2025_09_13_032700) do
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
    t.integer "card_templates_id", null: false
    t.string "full_citation"
    t.string "case_name"
    t.string "case_short_name"
    t.text "material_facts"
    t.text "issue"
    t.text "key_principle"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["card_templates_id"], name: "index_cases_on_card_templates_id"
    t.index ["subject_id"], name: "index_cases_on_subject_id"
    t.index ["user_id"], name: "index_cases_on_user_id"
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

  add_foreign_key "card_templates", "subjects"
  add_foreign_key "card_templates", "users"
  add_foreign_key "cases", "card_templates", column: "card_templates_id"
  add_foreign_key "cases", "subjects"
  add_foreign_key "cases", "users"
  add_foreign_key "subjects", "users"
end
