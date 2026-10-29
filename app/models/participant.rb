class Participant < ApplicationRecord
  # Interface languages only; practice is always in English (NFR7).
  DISPLAY_LANGUAGES = %w[en es].freeze

  before_validation :assign_pseudonym, on: :create

  # Declared before evaluation_traces so the attempt (whose writing and recording point at traces) and the
  # conversations (whose turns do) are destroyed first.
  has_one :placement_attempt, class_name: "Placement::Attempt", dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :evaluation_traces, dependent: :destroy

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :pseudonym, presence: true, uniqueness: true
  validates :display_language, inclusion: { in: DISPLAY_LANGUAGES }, allow_nil: true

  def current_consent
    Consent.find_by(pseudonym: pseudonym, document_version: Consent::CURRENT_VERSION)
  end

  # The scenarios the learner has finished, for the path to move past (2026-10-29): a conversation that ended any way
  # but abandoned, with at least one message of theirs. The same rule that gives a conversation feedback.
  def completed_scenario_keys
    conversations.where(status: "finished", finished_reason: Conversation::FEEDBACK_REASONS)
                 .where(id: Conversation::Turn.where(speaker: "learner").select(:conversation_id))
                 .joins(:scenario).distinct.pluck("scenarios.key")
  end

  private

  # The pseudonym is the only identifier allowed in research data, so it must not derive from Clerk or the email.
  def assign_pseudonym
    self.pseudonym ||= "learner-#{SecureRandom.hex(4)}"
  end
end
