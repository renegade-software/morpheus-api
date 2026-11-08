# What Progreso shows, from the same counted conversations XP uses: the placement band, each skill's all-time
# average, and every step that earned XP or closed a stage, oldest first. Stage and XP totals come with GET /user.
module Progress
  SKILLS = %w[goal grammar vocabulary tone pronunciation rhythm].freeze

  def self.summary(participant)
    conversations = participant.conversations.counted.includes(:scenario, feedback: :scores)
                               .order(:finished_at, :id).to_a
    attempt = participant.placement_attempt
    { placement: attempt&.level_low && { level_low: attempt.level_low, level_high: attempt.level_high },
      skills: skills(conversations.select { _1.feedback&.status == "ready" }),
      history: history(participant, conversations).sort_by { _1[:at] } }
  end

  # The average of every score for each skill; a skill with no evidence yet has no score.
  def self.skills(rated)
    SKILLS.map do |skill|
      scores = rated.filter_map { |conversation| conversation.feedback.scores.find { _1.skill == skill }&.score }
      { skill: skill, score: scores.empty? ? nil : scores.sum.fdiv(scores.size).round(1) }
    end
  end

  def self.history(participant, conversations)
    points = Xp.awards(participant).to_h { [ _1.conversation_id, _1.points ] }
    conversation_rows(conversations, points) + review_rows(participant) + quiz_rows(participant)
  end

  # attempt: which try at that scenario this was, the same count that lowers a repeat's XP.
  def self.conversation_rows(conversations, points)
    attempts = Hash.new(0)
    conversations.map do |conversation|
      key = conversation.scenario.key
      attempts[key] += 1
      { kind: "conversation", at: conversation.finished_at, scenario: key, mode: conversation.mode,
        attempt: attempts[key], goals_met: conversation.goals.count { _1.fetch("met") },
        goals: conversation.goals.size, points: points.fetch(conversation.id) }
    end
  end

  def self.review_rows(participant)
    participant.stage_reviews.map do |review|
      { kind: "review", at: review.acknowledged_at, stage: review.stage, points: StageReview::POINTS }
    end
  end

  def self.quiz_rows(participant)
    participant.stage_quiz_attempts.map do |attempt|
      { kind: "quiz", at: attempt.created_at, stage: attempt.stage, correct: attempt.correct,
        total: attempt.items.size, passed: attempt.passed, points: 0 }
    end
  end
  private_class_method :skills, :history, :conversation_rows, :review_rows, :quiz_rows
end
