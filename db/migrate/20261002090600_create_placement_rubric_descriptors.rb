class CreatePlacementRubricDescriptors < ActiveRecord::Migration[8.1]
  def change
    # The CEFR descriptor text Claude scores against, one row per skill, criterion and level, quoted word for word.
    # Stored per form so a rubric change is a new form, like any other content change.
    create_table :placement_rubric_descriptors do |t|
      t.references :placement_form, null: false, foreign_key: true
      t.string  :skill,     null: false
      t.string  :criterion, null: false
      t.integer :level,     null: false
      t.text    :text,      null: false
      t.string  :source,    null: false

      t.timestamps
    end

    add_index :placement_rubric_descriptors, [ :placement_form_id, :skill, :criterion, :level ],
      unique: true, name: "index_placement_rubric_descriptors_uniqueness"
  end
end
