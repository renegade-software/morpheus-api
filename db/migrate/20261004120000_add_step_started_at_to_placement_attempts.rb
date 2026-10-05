class AddStepStartedAtToPlacementAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :placement_attempts, :step_started_at, :datetime
  end
end
