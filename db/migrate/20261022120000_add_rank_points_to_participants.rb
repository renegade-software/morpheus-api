class AddRankPointsToParticipants < ActiveRecord::Migration[8.1]
  def change
    # Starts from the placement score and moves with every conversation. Null until the placement test is scored.
    add_column :participants, :rank_points, :integer

    # Learners who already finished the placement test get their starting points now, with the same formula
    # as RankPoints.from_placement (400 + 400 × score).
    reversible do |direction|
      direction.up do
        execute <<~SQL
          UPDATE participants
          SET rank_points = ROUND(400 + 400 * placement_attempts.score)
          FROM placement_attempts
          WHERE placement_attempts.participant_id = participants.id
            AND placement_attempts.status = 'completed'
            AND placement_attempts.score IS NOT NULL
        SQL
      end
    end
  end
end
