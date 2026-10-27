# One learner's conversation with a scenario's character: the transcript, the latest goal checks and whether it's
# still going. Holds learner text, so it belongs to the participant and is deleted with them.
class Conversation < ApplicationRecord
  STATUSES = %w[active finished].freeze
  # How it ended: every goal met, the last extra turn used, the learner pressed Terminar, or they left (abandoned).
  FINISHED_REASONS = %w[goals_met turn_limit ended_by_learner abandoned].freeze
  # No typing, click or scroll for this long means the learner has left (2026-10-27). The chat screen measures it;
  # the server only sees messages, so it applies the same limit to conversations whose tab was closed.
  IDLE_LIMIT = 3.minutes

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
  # Ends the participant's open conversations with no message within the idle limit: a closed tab can't end its own.
  # They end when the limit ran out, not now, so their duration in the analysis isn't stretched by the time away.
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

  def active?
    status == "active"
  end

  def finish!(reason, at: Time.current)
    update!(status: "finished", finished_reason: reason, finished_at: at)
  end
end
