class AddCurrentLevelToParticipants < ActiveRecord::Migration[8.1]
  def change
    # Starts at the placement attempt's level_low and rises as conversations show progress.
    # The intake range stays on the attempt, so the thesis can always compare against it.
    add_column :participants, :current_level, :integer
  end
end
