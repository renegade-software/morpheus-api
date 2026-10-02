class PointPlacementResultsAtTheItemBank < ActiveRecord::Migration[8.1]
  # Replaces the file-based references (content_version, item_key, prompt_id) with foreign keys into the item bank.
  # Fails if placement rows already exist in this database; delete those test rows first.
  def change
    remove_column :placement_attempts, :content_version, :string, null: false
    add_reference :placement_attempts, :placement_form, null: false, foreign_key: true

    remove_index  :placement_responses, [ :placement_attempt_id, :item_key ], unique: true
    remove_column :placement_responses, :item_key, :string, null: false
    remove_column :placement_responses, :section, :string, null: false
    add_reference :placement_responses, :placement_question, null: false, foreign_key: true
    add_index     :placement_responses, [ :placement_attempt_id, :placement_question_id ], unique: true,
                  name: "index_placement_responses_one_per_question"

    add_reference :placement_writings, :placement_task, null: false, foreign_key: true

    remove_column :placement_recordings, :prompt_id, :string, null: false
    add_reference :placement_recordings, :placement_task, null: false, foreign_key: true
  end
end
