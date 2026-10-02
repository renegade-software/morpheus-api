class RemoveSubmittedAtFromPlacementWritingsAndRecordings < ActiveRecord::Migration[8.1]
  # Drafts stay in the browser, so a row is only created on submit and created_at (server time) is the submission.
  def change
    remove_column :placement_writings, :submitted_at, :datetime
    remove_column :placement_recordings, :submitted_at, :datetime
  end
end
