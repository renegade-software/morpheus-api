class CreatePlacementSpeakingTasks < ActiveRecord::Migration[8.1]
  def change
    # The speaking prompts. A prompt is chosen by the learner's reading result, so each one lists the results it serves.
    create_table :placement_speaking_tasks do |t|
      t.references :placement_form, null: false, foreign_key: true
      t.string  :tier,            null: false
      t.integer :reading_results, array: true, null: false, default: []
      t.text    :prompt,          null: false
      t.text    :follow_up
      t.integer :seconds,         null: false
      t.jsonb   :scoring_rules,   null: false, default: []

      t.timestamps
    end

    add_index :placement_speaking_tasks, [ :placement_form_id, :tier ], unique: true
  end
end
