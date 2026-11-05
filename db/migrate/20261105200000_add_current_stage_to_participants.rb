# The stage the learner is on. Null until they first move up; until then it's the first stage of their placement level.
class AddCurrentStageToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :current_stage, :string
  end
end
