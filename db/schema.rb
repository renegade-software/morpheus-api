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

ActiveRecord::Schema[8.1].define(version: 2026_10_08_120000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

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
    t.bigint "placement_form_id", null: false
    t.datetime "step_started_at"
    t.integer "plays_used", default: 0, null: false
    t.integer "retakes_used", default: 0, null: false
    t.index ["participant_id"], name: "index_placement_attempts_on_participant_id", unique: true
    t.index ["placement_form_id"], name: "index_placement_attempts_on_placement_form_id"
  end

  create_table "placement_forms", force: :cascade do |t|
    t.string "name", null: false
    t.string "status", default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_placement_forms_on_name", unique: true
    t.index ["status"], name: "index_placement_forms_one_active", unique: true, where: "((status)::text = 'active'::text)"
  end

  create_table "placement_passages", force: :cascade do |t|
    t.bigint "placement_form_id", null: false
    t.string "section", null: false
    t.string "tier", null: false
    t.integer "level", null: false
    t.string "cefr_scale", null: false
    t.text "cefr_descriptor", null: false
    t.text "body"
    t.text "transcript"
    t.string "delivery"
    t.integer "seconds"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "plays"
    t.index ["placement_form_id", "section", "tier"], name: "idx_on_placement_form_id_section_tier_8b7a795014", unique: true
    t.index ["placement_form_id"], name: "index_placement_passages_on_placement_form_id"
  end

  create_table "placement_questions", force: :cascade do |t|
    t.bigint "placement_passage_id", null: false
    t.integer "position", null: false
    t.text "prompt", null: false
    t.jsonb "options", null: false
    t.integer "correct_option", null: false
    t.string "targets"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement_passage_id", "position"], name: "index_placement_questions_on_placement_passage_id_and_position", unique: true
    t.index ["placement_passage_id"], name: "index_placement_questions_on_placement_passage_id"
    t.check_constraint "correct_option >= 0 AND correct_option < jsonb_array_length(options)", name: "placement_questions_correct_option_in_options"
  end

  create_table "placement_recordings", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.text "transcript"
    t.jsonb "word_timings"
    t.jsonb "capture_metadata"
    t.integer "speaking_ms"
    t.integer "word_count"
    t.integer "long_pauses"
    t.boolean "timed_out", default: false, null: false
    t.bigint "evaluation_trace_id"
    t.integer "range_level"
    t.integer "accuracy_level"
    t.integer "fluency_level"
    t.integer "coherence_level"
    t.integer "overall_level"
    t.jsonb "evidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "placement_speaking_task_id", null: false
    t.index ["evaluation_trace_id"], name: "index_placement_recordings_on_evaluation_trace_id"
    t.index ["placement_attempt_id"], name: "index_placement_recordings_on_placement_attempt_id", unique: true
    t.index ["placement_speaking_task_id"], name: "index_placement_recordings_on_placement_speaking_task_id"
  end

  create_table "placement_responses", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.integer "selected_option"
    t.boolean "correct", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "placement_question_id", null: false
    t.index ["placement_attempt_id", "placement_question_id"], name: "index_placement_responses_one_per_question", unique: true
    t.index ["placement_attempt_id"], name: "index_placement_responses_on_placement_attempt_id"
    t.index ["placement_question_id"], name: "index_placement_responses_on_placement_question_id"
  end

  create_table "placement_rubric_descriptors", force: :cascade do |t|
    t.bigint "placement_form_id", null: false
    t.string "skill", null: false
    t.string "criterion", null: false
    t.integer "level", null: false
    t.text "text", null: false
    t.string "source", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement_form_id", "skill", "criterion", "level"], name: "index_placement_rubric_descriptors_uniqueness", unique: true
    t.index ["placement_form_id"], name: "index_placement_rubric_descriptors_on_placement_form_id"
  end

  create_table "placement_speaking_anchors", force: :cascade do |t|
    t.bigint "placement_speaking_task_id", null: false
    t.integer "level", null: false
    t.text "transcript", null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "speaking_ms", null: false
    t.integer "word_count", null: false
    t.integer "long_pauses", null: false
    t.index ["placement_speaking_task_id", "level"], name: "idx_on_placement_speaking_task_id_level_fd5cf47812", unique: true
    t.index ["placement_speaking_task_id"], name: "index_placement_speaking_anchors_on_placement_speaking_task_id"
  end

  create_table "placement_speaking_tasks", force: :cascade do |t|
    t.bigint "placement_form_id", null: false
    t.string "tier", null: false
    t.integer "reading_results", default: [], null: false, array: true
    t.text "prompt", null: false
    t.integer "seconds", null: false
    t.jsonb "scoring_rules", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "prep_seconds", default: 15, null: false
    t.integer "retakes", default: 1, null: false
    t.index ["placement_form_id", "tier"], name: "index_placement_speaking_tasks_on_placement_form_id_and_tier", unique: true
    t.index ["placement_form_id"], name: "index_placement_speaking_tasks_on_placement_form_id"
  end

  create_table "placement_writing_anchors", force: :cascade do |t|
    t.bigint "placement_writing_task_id", null: false
    t.integer "level", null: false
    t.text "text", null: false
    t.text "note", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement_writing_task_id", "level"], name: "idx_on_placement_writing_task_id_level_99def15e72", unique: true
    t.index ["placement_writing_task_id"], name: "index_placement_writing_anchors_on_placement_writing_task_id"
  end

  create_table "placement_writing_tasks", force: :cascade do |t|
    t.bigint "placement_form_id", null: false
    t.text "prompt", null: false
    t.jsonb "bullets", default: [], null: false
    t.integer "seconds", null: false
    t.jsonb "scoring_rules", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["placement_form_id"], name: "index_placement_writing_tasks_on_placement_form_id", unique: true
  end

  create_table "placement_writings", force: :cascade do |t|
    t.bigint "placement_attempt_id", null: false
    t.text "text"
    t.boolean "timed_out", default: false, null: false
    t.bigint "evaluation_trace_id"
    t.integer "production_level"
    t.integer "range_level"
    t.integer "accuracy_level"
    t.integer "coherence_level"
    t.integer "overall_level"
    t.jsonb "evidence"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "placement_writing_task_id", null: false
    t.index ["evaluation_trace_id"], name: "index_placement_writings_on_evaluation_trace_id"
    t.index ["placement_attempt_id"], name: "index_placement_writings_on_placement_attempt_id", unique: true
    t.index ["placement_writing_task_id"], name: "index_placement_writings_on_placement_writing_task_id"
  end

  create_table "solid_queue_batch_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "batch_id", null: false
    t.datetime "created_at", null: false
    t.index ["batch_id"], name: "index_solid_queue_batch_executions_on_batch_id"
    t.index ["job_id"], name: "index_solid_queue_batch_executions_on_job_id", unique: true
  end

  create_table "solid_queue_batches", force: :cascade do |t|
    t.string "active_job_batch_id"
    t.string "description"
    t.text "on_finish"
    t.text "on_success"
    t.text "on_failure"
    t.text "metadata"
    t.integer "total_jobs", default: 0, null: false
    t.integer "completed_jobs", default: 0, null: false
    t.integer "failed_jobs", default: 0, null: false
    t.datetime "enqueued_at"
    t.datetime "finished_at"
    t.datetime "failed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active_job_batch_id"], name: "index_solid_queue_batches_on_active_job_batch_id", unique: true
    t.index ["finished_at"], name: "index_solid_queue_batches_on_finished_at"
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.string "concurrency_key", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "index_solid_queue_blocked_executions_for_release"
    t.index ["expires_at", "concurrency_key"], name: "index_solid_queue_blocked_executions_for_maintenance"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.text "error"
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "queue_name", null: false
    t.string "class_name", null: false
    t.text "arguments"
    t.integer "priority", default: 0, null: false
    t.string "active_job_id"
    t.datetime "scheduled_at"
    t.datetime "finished_at"
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "batch_id"
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["batch_id"], name: "index_solid_queue_jobs_on_batch_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_for_filtering"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_for_alerting"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.string "queue_name", null: false
    t.datetime "created_at", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.bigint "supervisor_id"
    t.integer "pid", null: false
    t.string "hostname"
    t.text "metadata"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_poll_all"
    t.index ["queue_name", "priority", "job_id"], name: "index_solid_queue_poll_by_queue"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "task_key", null: false
    t.datetime "run_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.string "key", null: false
    t.string "schedule", null: false
    t.string "command", limit: 2048
    t.string "class_name"
    t.text "arguments"
    t.string "queue_name"
    t.integer "priority", default: 0
    t.boolean "static", default: true, null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.bigint "job_id", null: false
    t.string "queue_name", null: false
    t.integer "priority", default: 0, null: false
    t.datetime "scheduled_at", null: false
    t.datetime "created_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "index_solid_queue_dispatch_all"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.string "key", null: false
    t.integer "value", default: 1, null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "evaluation_traces", "participants"
  add_foreign_key "placement_attempts", "participants"
  add_foreign_key "placement_attempts", "placement_forms"
  add_foreign_key "placement_passages", "placement_forms"
  add_foreign_key "placement_questions", "placement_passages"
  add_foreign_key "placement_recordings", "evaluation_traces"
  add_foreign_key "placement_recordings", "placement_attempts"
  add_foreign_key "placement_recordings", "placement_speaking_tasks"
  add_foreign_key "placement_responses", "placement_attempts"
  add_foreign_key "placement_responses", "placement_questions"
  add_foreign_key "placement_rubric_descriptors", "placement_forms"
  add_foreign_key "placement_speaking_anchors", "placement_speaking_tasks"
  add_foreign_key "placement_speaking_tasks", "placement_forms"
  add_foreign_key "placement_writing_anchors", "placement_writing_tasks"
  add_foreign_key "placement_writing_tasks", "placement_forms"
  add_foreign_key "placement_writings", "evaluation_traces"
  add_foreign_key "placement_writings", "placement_attempts"
  add_foreign_key "placement_writings", "placement_writing_tasks"
  add_foreign_key "solid_queue_batch_executions", "solid_queue_batches", column: "batch_id", on_delete: :cascade
  add_foreign_key "solid_queue_batch_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
end
