module Xp
  FIRST_TRY = 50
  REPEAT_FACTOR = 0.8

  Award = Data.define(:conversation_id, :scenario_key, :points, :goals_met, :goals, :factor)

  def self.awards(participant)
    attempts = Hash.new(0)
    participant.conversations.counted.includes(:scenario).order(:finished_at, :id).map do |conversation|
      key = conversation.scenario.key
      factor = REPEAT_FACTOR**attempts[key]
      attempts[key] += 1
      Award.new(conversation_id: conversation.id, scenario_key: key,
                points: (FIRST_TRY * conversation.goals_met_share * factor).round,
                goals_met: conversation.goals.count { _1.fetch("met") }, goals: conversation.goals.size, factor: factor)
    end
  end

  def self.summary(participant)
    awards = awards(participant)
    by_scenario = awards.group_by(&:scenario_key).transform_values { _1.sum(&:points) }
    { total: awards.sum(&:points), last_change: awards.last&.points, by_scenario: by_scenario }
  end

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
