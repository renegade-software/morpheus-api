class CreatePlacementForms < ActiveRecord::Migration[8.1]
  def change
    # A form is one complete, frozen version of the test: its passages, questions, tasks, anchors and rubric.
    # Attempts point at a form, so every result can be traced to the exact content the learner saw.
    create_table :placement_forms do |t|
      t.string :name,   null: false, index: { unique: true }
      t.string :status, null: false, default: "draft"

      t.timestamps
    end

    # Only one form can be served to new learners at a time.
    add_index :placement_forms, :status, unique: true, where: "status = 'active'", name: "index_placement_forms_one_active"
  end
end
