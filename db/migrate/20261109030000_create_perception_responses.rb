# The 7-item perception questionnaire answered with each stage review, adapted from the Chiwi Tutor study.
# Answers are stored as given (1 strongly disagree … 5 strongly agree); the reverse-coded items are flipped at analysis.
class CreatePerceptionResponses < ActiveRecord::Migration[8.1]
  def change
    create_table :perception_responses do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :stage, null: false
      t.integer :robotic, limit: 2, null: false
      t.integer :friendly, limit: 2, null: false
      t.integer :easy_to_use, limit: 2, null: false
      t.integer :complex_to_use, limit: 2, null: false
      t.integer :good_solutions, limit: 2, null: false
      t.integer :could_not_help, limit: 2, null: false
      t.integer :useful_responses, limit: 2, null: false
      t.timestamps
    end
    add_index :perception_responses, %i[participant_id stage], unique: true
  end
end
