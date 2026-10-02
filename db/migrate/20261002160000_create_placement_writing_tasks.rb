class CreatePlacementWritingTasks < ActiveRecord::Migration[8.1]
  def change
    # The one writing task per form: a situation plus bullets that climb in level.
    create_table :placement_writing_tasks do |t|
      t.references :placement_form, null: false, foreign_key: true, index: { unique: true }
      t.text    :prompt,        null: false
      t.jsonb   :bullets,       null: false, default: []
      t.integer :seconds,       null: false
      t.jsonb   :scoring_rules, null: false, default: []

      t.timestamps
    end
  end
end
