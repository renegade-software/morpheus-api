class AddPrepSecondsToPlacementSpeakingTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :placement_speaking_tasks, :prep_seconds, :integer, null: false, default: 15
  end
end
