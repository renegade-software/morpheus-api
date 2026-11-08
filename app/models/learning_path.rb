# What a learner may start, by the same rules as the trail in morpheus-ui (src/path/path.ts and HomePage): only on
# their current stage, the next stop or one already done (a repeat), the review once the first three activities are
# done, and the quiz once everything before it is done and the stage has 200 XP, or after it's been passed.
module LearningPath
  ORDER = YAML.safe_load_file(Rails.root.join("content", "path.yaml")).transform_values(&:freeze).freeze
  BEFORE_REVIEW = 3
  # Mirrors QUIZ_GOAL in morpheus-ui src/path/xp.ts.
  QUIZ_GOAL = 200

  def self.can_play?(participant, key)
    stage = participant.stage
    scenarios = ORDER[stage]
    index = scenarios&.index(key)
    return false unless index

    done = participant.completed_scenario_keys
    return true if done.include?(key)
    return false unless (scenarios.first(index) - done).empty?

    index < BEFORE_REVIEW || participant.stage_reviews.exists?(stage: stage)
  end

  def self.can_review?(participant, stage)
    return false unless stage == participant.stage

    (ORDER.fetch(stage).first(BEFORE_REVIEW) - participant.completed_scenario_keys).empty?
  end

  def self.can_take_quiz?(participant, stage)
    return false unless stage == participant.stage
    return true if participant.stage_quiz_attempts.passed.exists?(stage: stage)
    return false unless (ORDER.fetch(stage) - participant.completed_scenario_keys).empty?
    return false unless participant.stage_reviews.exists?(stage: stage)

    stage_points(participant, stage) >= QUIZ_GOAL
  end

  # The stage's XP as the trail counts it: its six activities (repeats included) plus its review.
  def self.stage_points(participant, stage)
    xp = Xp.summary(participant)
    ORDER.fetch(stage).sum { xp[:by_scenario].fetch(_1, 0) } + xp[:by_review].fetch(stage, 0)
  end
end
