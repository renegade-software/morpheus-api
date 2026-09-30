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

ActiveRecord::Schema[8.1].define(version: 2026_09_30_025014) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "consents", force: :cascade do |t|
    t.string "pseudonym", null: false
    t.string "document_version", null: false
    t.boolean "adult", null: false
    t.boolean "participate", null: false
    t.boolean "personal_data", null: false
    t.boolean "sensitive_data", null: false
    t.boolean "audio_recording", null: false
    t.boolean "transcription", null: false
    t.boolean "receive_results", null: false
    t.datetime "accepted_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pseudonym"], name: "index_consents_on_pseudonym"
  end

  create_table "participants", force: :cascade do |t|
    t.string "clerk_user_id", null: false
    t.string "pseudonym", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["clerk_user_id"], name: "index_participants_on_clerk_user_id", unique: true
    t.index ["pseudonym"], name: "index_participants_on_pseudonym", unique: true
  end
end
