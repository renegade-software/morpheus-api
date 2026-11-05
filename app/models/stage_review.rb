class StageReview < ApplicationRecord
  POINTS = 25
  # The UI's stage keys (morpheus-ui src/path/stages.ts); the API has no other notion of stages.
  STAGES = %w[firstSteps onFoot path crossing bridge firmFooting lookout bend longRoad goodPace summit beyond].freeze
  # Goal comments are about the task, not the language, so they aren't mistakes to recap.
  EXCLUDED_SKILLS = %w[goal].freeze

  belongs_to :participant

  validates :stage, inclusion: { in: STAGES }, uniqueness: { scope: :participant_id }
  validates :acknowledged_at, presence: true

  def self.acknowledge!(participant, stage)
    participant.stage_reviews.create_or_find_by!(stage: stage) { _1.acknowledged_at = Time.current }
  end

  # The learner's mistakes in the given scenarios, grouped by category, most frequent first.
  # Comments the learner flagged as wrong are left out.
  def self.mistakes(participant, scenario_keys)
    comments = Feedback::Comment
               .joins(feedback: { conversation: :scenario })
               .where(feedbacks: { status: "ready", conversation_id: participant.conversations.counted.select(:id) })
               .where(scenarios: { key: scenario_keys }, flagged_as: nil)
               .where.not(skill: EXCLUDED_SKILLS)
               .order(:id)

    comments.group_by(&:category)
            .map { |category, group| { category: category, skill: group.first.skill, count: group.size, mistakes: group.map { mistake(_1) } } }
            .sort_by { -_1[:count] }
  end

  def self.mistake(comment)
    { id: comment.id, quote: comment.quote, rewrite: comment.rewrite, explanation: comment.explanation }
  end
  private_class_method :mistake
end
