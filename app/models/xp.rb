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

  # One counted conversation's share: what it earned and how, for the screen at its end.
  Award = Data.define(:conversation_id, :points, :goals_met, :goals, :factor)

  # Every counted conversation's award, oldest first.
  def self.awards(participant)
    attempts = Hash.new(0)
    participant.conversations.counted.includes(:scenario).order(:finished_at, :id).map do |conversation|
      key = conversation.scenario.key
      factor = REPEAT_FACTORS[[ attempts[key], REPEAT_FACTORS.size - 1 ].min]
      attempts[key] += 1
      Award.new(conversation_id: conversation.id, points: (FIRST_TRY * conversation.goals_met_share * factor).round,
                goals_met: conversation.goals.count { _1.fetch("met") }, goals: conversation.goals.size, factor: factor)
    end
  end

  # The total and the most recent change, for the XP card on Inicio.
  def self.summary(participant)
    points = awards(participant).map(&:points)
    { total: points.sum, last_change: points.last }
  end

  # What one finished conversation earned and the total before and after it; nil if it doesn't count (abandoned, or
  # the learner never wrote). Totals run up to this conversation, so the screen shows the jump it made.
  def self.for(conversation)
    awards = awards(conversation.participant)
    index = awards.index { _1.conversation_id == conversation.id }
    return unless index

    award = awards[index]
    before = awards.first(index).sum(&:points)
    { earned: award.points, goals_met: award.goals_met, goals: award.goals, factor: award.factor,
      total_before: before, total_after: before + award.points }
  end
end
