class RemoveFollowUpFromPlacementSpeakingTasks < ActiveRecord::Migration[8.1]
  # The shared "…and tell me anything else you'd like." pushed for no particular skill, so prompts now stand alone.
  def change
    remove_column :placement_speaking_tasks, :follow_up, :text
  end
end
