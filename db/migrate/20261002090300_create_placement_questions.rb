class CreatePlacementQuestions < ActiveRecord::Migration[8.1]
  def change
    # correct_option is the answer key; the learner serializer never sends it.
    create_table :placement_questions do |t|
      t.references :placement_passage, null: false, foreign_key: true
      t.integer :position,       null: false
      t.text    :prompt,         null: false
      t.jsonb   :options,        null: false
      t.integer :correct_option, null: false
      t.string  :targets

      t.timestamps
    end

    add_index :placement_questions, [ :placement_passage_id, :position ], unique: true
    add_check_constraint :placement_questions,
      "correct_option >= 0 AND correct_option < jsonb_array_length(options)",
      name: "placement_questions_correct_option_in_options"
  end
end
