module Xp
  FIRST_TRY = 50
  REPEAT_FACTOR = 0.8

  Award = Data.define(:conversation_id, :scenario_key, :points, :goals_met, :goals, :factor, :finished_at)

  def self.awards(participant)
    attempts = Hash.new(0)
    participant.conversations.counted.includes(:scenario).order(:finished_at, :id).map do |conversation|
      key = conversation.scenario.key
      factor = REPEAT_FACTOR**attempts[key]
      attempts[key] += 1
      Award.new(conversation_id: conversation.id, scenario_key: key,
                points: (FIRST_TRY * conversation.goals_met_share * factor).round,
                goals_met: conversation.goals.count { _1.fetch("met") }, goals: conversation.goals.size, factor: factor,
                finished_at: conversation.finished_at)
    end
  end

  def self.summary(participant)
    awards = awards(participant)
    reviews = participant.stage_reviews.order(:acknowledged_at, :id).to_a
    by_scenario = awards.group_by(&:scenario_key).transform_values { _1.sum(&:points) }
    { total: awards.sum(&:points) + (reviews.size * StageReview::POINTS),
      last_change: last_change(awards.last, reviews.last),
      by_scenario: by_scenario,
      by_review: reviews.to_h { [ _1.stage, StageReview::POINTS ] } }
  end

  def self.last_change(award, review)
    return award&.points unless review
    return StageReview::POINTS if award.nil? || review.acknowledged_at > award.finished_at

    award.points
  end
  private_class_method :last_change

  def self.for(conversation)
    awards = awards(conversation.participant)
    index = awards.index { _1.conversation_id == conversation.id }
    return unless index

    award = awards[index]
    reviews_before = conversation.participant.stage_reviews.where(acknowledged_at: ...conversation.finished_at).count
    before = awards.first(index).sum(&:points) + (reviews_before * StageReview::POINTS)
    { earned: award.points, goals_met: award.goals_met, goals: award.goals, factor: award.factor,
      total_before: before, total_after: before + award.points }
  end
end
