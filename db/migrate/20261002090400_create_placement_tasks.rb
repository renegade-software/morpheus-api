class CreatePlacementTasks < ActiveRecord::Migration[8.1]
  def change
    # The writing task and the speaking prompts. A speaking prompt is chosen by the learner's reading result,
    # so each one lists the reading results it serves.
    create_table :placement_tasks do |t|
      t.references :placement_form, null: false, foreign_key: true
      t.string  :kind,            null: false
      t.string  :tier
      t.integer :reading_results, array: true, null: false, default: []
      t.text    :prompt,          null: false
      t.jsonb   :bullets,         null: false, default: []
      t.text    :follow_up
      t.integer :seconds,         null: false
      t.jsonb   :scoring_rules,   null: false, default: []

      t.timestamps
    end

    add_index :placement_tasks, [ :placement_form_id, :kind, :tier ], unique: true
  end
end
