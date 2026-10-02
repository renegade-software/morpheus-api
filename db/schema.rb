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

ActiveRecord::Schema[8.1].define(version: 2026_10_01_120500) do
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

  create_table "evaluation_traces", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.string "step", null: false
    t.string "model", null: false
    t.string "effort"
    t.string "prompt_path", null: false
    t.string "prompt_sha256", null: false
    t.jsonb "input"
    t.jsonb "output"
    t.integer "input_tokens"
    t.integer "output_tokens"
    t.integer "latency_ms"
    t.decimal "cost_usd", precision: 8, scale: 5
    t.string "status", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_evaluation_traces_on_participant_id"
  end

  create_table "participants", force: :cascade do |t|
    t.string "clerk_user_id", null: false
    t.string "pseudonym", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "current_level"
    t.index ["clerk_user_id"], name: "index_participants_on_clerk_user_id", unique: true
    t.index ["pseudonym"], name: "index_participants_on_pseudonym", unique: true
  end

  create_table "placement_attempts", force: :cascade do |t|
    t.bigint "participant_id", null: false
    t.string "status", default: "in_progress", null: false
    t.string "content_version", null: false
    t.string "current_step"
    t.integer "reading_result"
    t.integer "listening_result"
    t.integer "writing_level"
    t.integer "speaking_level"
    t.decimal "score", precision: 4, scale: 2
    t.integer "level_low"
    t.integer "level_high"
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["participant_id"], name: "index_placement_attempts_on_participant_id", unique: true
  end

  create_table "placement_recordings", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.string "prompt_id", null: false
    t.text "transcript"
    t.jsonb "word_timings"
    t.jsonb "capture_metadata"
    t.integer "speaking_ms"
    t.integer "word_count"
    t.integer "long_pauses"
    t.boolean "timed_out", default: false, null: false
    t.datetime "submitted_at", null: false
    t.bigint "evaluation_trace_id"
    t.integer "range_level"
    t.integer "accuracy_level"
    t.integer "fluency_level"
    t.integer "coherence_level"
    t.integer "overall_level"
    t.jsonb "evidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_trace_id"], name: "index_placement_recordings_on_evaluation_trace_id"
    t.index ["placement_attempt_id"], name: "index_placement_recordings_on_placement_attempt_id", unique: true
  end

  create_table "placement_responses", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.string "section", null: false
    t.string "item_key", null: false
    t.integer "selected_option"
    t.boolean "correct", null: false
    t.datetime "shown_at", null: false
    t.datetime "answered_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement_attempt_id", "item_key"], name: "index_placement_responses_on_placement_attempt_id_and_item_key", unique: true
    t.index ["placement_attempt_id"], name: "index_placement_responses_on_placement_attempt_id"
  end

  create_table "placement_writings", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.text "text"
    t.boolean "timed_out", default: false, null: false
    t.datetime "submitted_at", null: false
    t.bigint "evaluation_trace_id"
    t.integer "production_level"
    t.integer "range_level"
    t.integer "accuracy_level"
    t.integer "coherence_level"
    t.integer "overall_level"
    t.jsonb "evidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["evaluation_trace_id"], name: "index_placement_writings_on_evaluation_trace_id"
    t.index ["placement_attempt_id"], name: "index_placement_writings_on_placement_attempt_id", unique: true
  end

  add_foreign_key "evaluation_traces", "participants"
  add_foreign_key "placement_attempts", "participants"
  add_foreign_key "placement_recordings", "evaluation_traces"
  add_foreign_key "placement_recordings", "placement_attempts"
  add_foreign_key "placement_responses", "placement_attempts"
  add_foreign_key "placement_writings", "evaluation_traces"
  add_foreign_key "placement_writings", "placement_attempts"
end
