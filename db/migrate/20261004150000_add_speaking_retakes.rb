class AddSpeakingRetakes < ActiveRecord::Migration[8.1]
  def change
    add_column :placement_speaking_tasks, :retakes, :integer, null: false, default: 1
    add_column :placement_attempts, :retakes_used, :integer, null: false, default: 0
  end
end
