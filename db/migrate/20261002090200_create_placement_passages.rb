class CreatePlacementPassages < ActiveRecord::Migration[8.1]
  def change
    # A reading text or a listening clip. Listening audio is an Active Storage attachment (has_one_attached :audio).
    # The transcript is for reviewers and the thesis only; the learner serializer never sends it.
    create_table :placement_passages do |t|
      t.references :placement_form, null: false, foreign_key: true
      t.string  :section,         null: false
      t.string  :tier,            null: false
      t.integer :level,           null: false
      t.string  :cefr_scale,      null: false
      t.text    :cefr_descriptor, null: false
      t.text    :body
      t.text    :transcript
      t.string  :delivery
      t.integer :seconds

      t.timestamps
    end

    add_index :placement_passages, [ :placement_form_id, :section, :tier ], unique: true
  end
end
