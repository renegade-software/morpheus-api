class CreatePlacementResponses < ActiveRecord::Migration[8.1]
  def change
    # One row per multiple-choice answer,
    create_table :placement_responses do |t|
      t.references :placement_attempt, null: false, foreign_key: true
      t.string   :section,  null: false
      t.string   :item_key, null: false
      t.integer  :selected_option
      t.boolean  :correct,  null: false
      t.datetime :shown_at, null: false
      t.datetime :answered_at

      t.timestamps
    end

    add_index :placement_responses, [:placement_attempt_id, :item_key], unique: true
  end
end
