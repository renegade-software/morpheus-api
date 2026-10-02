class CreatePlacementRecordings < ActiveRecord::Migration[8.1]
  def change
    # The speaking task and its accepted rating in one row; the audio is an Active Storage attachment, added with S3 in 3b.
    # Rejected ratings (failed checks, retries) stay only in evaluation_traces.
    # Levels are integers (A1 = 0 … C2 = 5), one column per Table 3 criterion; Interaction is left out because the task is a monologue.
    create_table :placement_recordings do |t|
      t.references :placement_attempt, null: false, foreign_key: true, index: { unique: true }
      t.string   :prompt_id,    null: false
      # audio: has_one_attached :audio (Active Storage, S3); the file's key lives in active_storage_blobs, not here
      t.text     :transcript
      t.jsonb    :word_timings
      t.jsonb    :capture_metadata
      t.integer  :speaking_ms
      t.integer  :word_count
      t.integer  :long_pauses
      t.boolean  :timed_out,    null: false, default: false
      t.datetime :submitted_at, null: false

      t.references :evaluation_trace, foreign_key: true
      t.integer :range_level
      t.integer :accuracy_level
      t.integer :fluency_level
      t.integer :coherence_level
      t.integer :overall_level
      t.jsonb   :evidence

      t.timestamps
    end
  end
end
