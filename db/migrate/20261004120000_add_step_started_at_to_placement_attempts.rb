class AddStepStartedAtToPlacementAttempts < ActiveRecord::Migration[8.1]
  # When the learner pressed Empezar on the current step, stamped by the server. Time left is worked out from it, so
  # a refresh resumes the clock instead of starting it over. Cleared each time the attempt moves to the next step.
  def change
    add_column :placement_attempts, :step_started_at, :datetime
  end
end
