class AddPrepSecondsToPlacementSpeakingTasks < ActiveRecord::Migration[8.1]
  # Thinking time before the recording starts, stored per task like the listening timing, so each form records the
  # conditions its learners had. Existing tasks get the 15 s decided on 2026-10-04.
  def change
    add_column :placement_speaking_tasks, :prep_seconds, :integer, null: false, default: 15
  end
end
