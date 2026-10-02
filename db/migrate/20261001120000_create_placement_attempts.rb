class CreatePlacementAttempts < ActiveRecord::Migration[8.1]
  def change
    # One attempt per learner. Levels are integers (A1 = 0 … C2 = 5) and only become "A2" on screen.
    # writing_level and speaking_level are copied from the accepted ratings, so the whole intake result is one row.
    create_table :placement_attempts do |t|
      t.references :participant, null: false, foreign_key: true, index: { unique: true }
      t.string   :status,          null: false, default: "in_progress"
      t.string   :content_version, null: false
      t.string   :current_step
      t.integer  :reading_result
      t.integer  :listening_result
      t.integer  :writing_level
      t.integer  :speaking_level
      t.decimal  :score, precision: 4, scale: 2
      t.integer  :level_low
      t.integer  :level_high
      t.datetime :started_at, null: false
      t.datetime :completed_at

      t.timestamps
    end
  end
end
