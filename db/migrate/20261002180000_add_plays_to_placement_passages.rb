class AddPlaysToPlacementPassages < ActiveRecord::Migration[8.1]
  # Listening timing moves from constants in Placement::Steps onto each clip, so a form records the conditions its
  # learners had. Existing clips get the values they were served with (2 plays, 30 s to answer).
  def up
    add_column :placement_passages, :plays, :integer
    execute "UPDATE placement_passages SET plays = 2, seconds = 30 WHERE section = 'listening'"
  end

  def down
    execute "UPDATE placement_passages SET seconds = NULL WHERE section = 'listening'"
    remove_column :placement_passages, :plays
  end
end
