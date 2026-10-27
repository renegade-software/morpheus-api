# One learner's conversation with a scenario's character: the transcript, the latest goal checks and whether it's
# still going. Holds learner text, so it belongs to the participant and is deleted with them.
class Conversation < ApplicationRecord
  STATUSES = %w[active finished].freeze
  # How it ended: every goal met, the last extra turn used, or the learner pressed Terminar.
  FINISHED_REASONS = %w[goals_met turn_limit ended_by_learner].freeze

  belongs_to :participant
  belongs_to :scenario
  # Declared before evaluation_traces: turns point at traces, so they go first when a conversation is destroyed.
  has_many :turns, -> { order(:position) }, dependent: :destroy
  has_many :evaluation_traces, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :finished_reason, inclusion: { in: FINISHED_REASONS }, allow_nil: true

  def self.start!(participant, scenario)
    transaction do
      conversation = create!(participant: participant, scenario: scenario,
                             goals: scenario.goal_ids.map { { "goal_id" => _1, "evidence" => nil, "met" => false } })
      conversation.turns.create!(position: 0, speaker: "character", text: scenario.opening)
      conversation
    end
  end

  # A met goal stays met, with the evidence that first met it. The agent rechecks every goal from the whole transcript
  # on each turn, and a later, stricter reading of the same words mustn't untick what the learner already saw met.
  def self.merge_goals(previous, checks)
    met = previous.select { _1.fetch("met") }.index_by { _1.fetch("goal_id") }
    checks.map { met.fetch(_1.fetch("goal_id"), _1) }
  end

  def all_goals_met?
    goals.all? { _1.fetch("met") }
  end

  def active?
    status == "active"
  end

  def finish!(reason)
    update!(status: "finished", finished_reason: reason, finished_at: Time.current)
  end
end
