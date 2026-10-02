class CreatePlacementWritingAnchors < ActiveRecord::Migration[8.1]
  def change
    # Sample written answers at known levels that go into Claude's scoring prompt; never sent to learners.
    create_table :placement_writing_anchors do |t|
      t.references :placement_writing_task, null: false, foreign_key: true
      t.integer :level, null: false
      t.text    :text,  null: false
      t.text    :note,  null: false

      t.timestamps
    end

    add_index :placement_writing_anchors, [ :placement_writing_task_id, :level ], unique: true
  end
end
