class AddSpeakingRetakes < ActiveRecord::Migration[8.1]
  # A learner may record the spoken answer again before sending it. How many times is stored per task, like the other
  # timings, so each form records its conditions (1, decided 2026-10-04); the attempt counts how many were used, which
  # the analysis keeps, so it isn't reset when the attempt moves on.
  def change
    add_column :placement_speaking_tasks, :retakes, :integer, null: false, default: 1
    add_column :placement_attempts, :retakes_used, :integer, null: false, default: 0
  end
end
