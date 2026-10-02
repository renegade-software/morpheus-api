class CreatePlacementAnchors < ActiveRecord::Migration[8.1]
  def change
    # Sample answers at known levels that go into Claude's scoring prompt; never sent to learners.
    create_table :placement_anchors do |t|
      t.references :placement_task, null: false, foreign_key: true
      t.integer :level,            null: false
      t.text    :text,             null: false
      t.text    :note,             null: false
      t.integer :speaking_seconds

      t.timestamps
    end

    add_index :placement_anchors, [ :placement_task_id, :level ], unique: true
  end
end
