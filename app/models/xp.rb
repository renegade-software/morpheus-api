# XP, the points learners see on the path (2026-10-22): earned per conversation, opening the level test at 400 and,
# with the final test passed, the level-up at 800. Never taken away (2026-10-29): a conversation that misses goals
# earns less and has to be played again instead. Worked out from the saved conversations every time, not stored, so
# it can't drift from what happened. The hidden Elo-style rank points from placement are separate (RankPoints).
module Xp
  # A conversation's worth the first time, scaled by the share of goals met. The UI shows it as the stake
  # (FIRST_TRY_POINTS in path/xp.ts); keep the two in step.
  FIRST_TRY = 50
  # Each later attempt at the same scenario earns half, then a quarter.
  REPEAT_FACTORS = [ 1, 0.5, 0.25 ].freeze

  # What each counted conversation earned, oldest first.
  def self.earned(participant)
    attempts = Hash.new(0)
    participant.conversations.counted.includes(:scenario).order(:finished_at, :id).map do |conversation|
      key = conversation.scenario.key
      factor = REPEAT_FACTORS[[ attempts[key], REPEAT_FACTORS.size - 1 ].min]
      attempts[key] += 1
      (FIRST_TRY * conversation.goals_met_share * factor).round
    end
  end

  # The total and the most recent change, for the XP card on Inicio.
  def self.summary(participant)
    earned = earned(participant)
    { total: earned.sum, last_change: earned.last }
  end
end
