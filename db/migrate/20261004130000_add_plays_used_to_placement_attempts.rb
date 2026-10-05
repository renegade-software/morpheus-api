class AddPlaysUsedToPlacementAttempts < ActiveRecord::Migration[8.1]
  # How many times the learner has played the current listening clip, counted by the server so a refresh can't give
  # plays back. Reset each time the attempt moves to the next step.
  def change
    add_column :placement_attempts, :plays_used, :integer, null: false, default: 0
  end
end
