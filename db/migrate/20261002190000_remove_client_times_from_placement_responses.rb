class RemoveClientTimesFromPlacementResponses < ActiveRecord::Migration[8.1]
  # Both came from the learner's device clock. created_at (server time, when the step's answers arrive) replaces them,
  # and a timed-out answer is already a null selected_option.
  def change
    remove_column :placement_responses, :shown_at, :datetime
    remove_column :placement_responses, :answered_at, :datetime
  end
end
