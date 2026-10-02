class CreatePlacementSpeakingAnchors < ActiveRecord::Migration[8.1]
  def change
    # Sample spoken answers at known levels that go into Claude's scoring prompt; never sent to learners.
    create_table :placement_speaking_anchors do |t|
      t.references :placement_speaking_task, null: false, foreign_key: true
      t.integer :level,            null: false
      t.text    :transcript,       null: false
      t.text    :note,             null: false
      t.integer :speaking_seconds, null: false

      t.timestamps
    end

    add_index :placement_speaking_anchors, [ :placement_speaking_task_id, :level ], unique: true
  end
end
