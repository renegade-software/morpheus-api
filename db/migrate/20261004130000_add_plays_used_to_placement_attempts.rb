class AddPlaysUsedToPlacementAttempts < ActiveRecord::Migration[8.1]
  def change
    add_column :placement_attempts, :plays_used, :integer, null: false, default: 0
  end
end
