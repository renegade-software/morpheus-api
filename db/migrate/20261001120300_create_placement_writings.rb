class CreatePlacementWritings < ActiveRecord::Migration[8.1]
  def change
    # The essay and its accepted rating in one row, so analysis needs no extra joins.
    # Rejected ratings (failed checks, retries) stay only in evaluation_traces.
    # Levels are integers (A1 = 0 … C2 = 5), one column per Companion Volume scale so they can be averaged directly.
    create_table :placement_writings do |t|
      t.references :placement_attempt, null: false, foreign_key: true, index: { unique: true }
      t.text     :text
      t.boolean  :timed_out,    null: false, default: false
      t.datetime :submitted_at, null: false

      t.references :evaluation_trace, foreign_key: true
      t.integer :production_level
      t.integer :range_level
      t.integer :accuracy_level
      t.integer :coherence_level
      t.integer :overall_level
      t.jsonb   :evidence

      t.timestamps
    end
  end
end
