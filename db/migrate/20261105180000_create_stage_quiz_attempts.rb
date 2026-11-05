# Every try at a stage's grammar quiz. `items` keeps the questions as they were shown, with the learner's choices.
class CreateStageQuizAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :stage_quiz_attempts do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :stage, null: false
      t.jsonb :items, null: false
      t.integer :correct, null: false
      t.boolean :passed, null: false
      t.timestamps
    end
    add_index :stage_quiz_attempts, %i[participant_id stage]
  end
end
