class Conversation < ApplicationRecord
  STATUSES = %w[active finished].freeze
  FINISHED_REASONS = %w[goals_met turn_limit ended_by_learner abandoned].freeze
  FEEDBACK_REASONS = %w[goals_met turn_limit ended_by_learner].freeze
  IDLE_LIMIT = 3.minutes

  belongs_to :participant
  belongs_to :scenario
  has_one :feedback, dependent: :destroy
  has_many :turns, -> { order(:position) }, dependent: :destroy
  has_many :evaluation_traces, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :finished_reason, inclusion: { in: FINISHED_REASONS }, allow_nil: true

  scope :counted, lambda {
    where(status: "finished", finished_reason: FEEDBACK_REASONS)
      .where(id: Conversation::Turn.where(speaker: "learner").select(:conversation_id))
  }

  def self.start!(participant, scenario)
    transaction do
      conversation = create!(participant: participant, scenario: scenario,
                             goals: scenario.goal_ids.map { { "goal_id" => _1, "evidence" => nil, "met" => false } })
      conversation.turns.create!(position: 0, speaker: "character", text: scenario.opening)
      conversation
    end
  end

  def self.abandon_idle!(participant)
    participant.conversations.where(status: "active").find_each do |conversation|
      idle_until = conversation.turns.last.created_at + IDLE_LIMIT
      conversation.finish!("abandoned", at: idle_until) if idle_until.past?
    end
  end

  def self.merge_goals(previous, checks)
    met = previous.select { _1.fetch("met") }.index_by { _1.fetch("goal_id") }
    checks.map { met.fetch(_1.fetch("goal_id"), _1) }
  end

  def all_goals_met?
    goals.all? { _1.fetch("met") }
  end

  def goals_met_share
    goals.count { _1.fetch("met") }.fdiv(goals.size)
  end

  def active?
    status == "active"
  end

  def finish!(reason, at: Time.current)
    update!(status: "finished", finished_reason: reason, finished_at: at)
    request_feedback if FEEDBACK_REASONS.include?(reason) && turns.exists?(speaker: "learner")
  end

  private

  def request_feedback
    language = participant.display_language || "es"
    GenerateFeedbackJob.perform_later(create_feedback!(mode: scenario.mode, display_language: language))
  end
end
