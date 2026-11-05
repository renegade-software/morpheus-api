# One row per stage whose review (the recap of that stage's mistakes so far) the learner has acknowledged.
class CreateStageReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :stage_reviews do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :stage, null: false
      t.datetime :acknowledged_at, null: false
      t.timestamps
    end
    add_index :stage_reviews, %i[participant_id stage], unique: true
  end
end
