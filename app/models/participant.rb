class Participant < ApplicationRecord
  DISPLAY_LANGUAGES = %w[en es].freeze

  before_validation :assign_pseudonym, on: :create

  has_one :placement_attempt, class_name: "Placement::Attempt", dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :evaluation_traces, dependent: :destroy

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :pseudonym, presence: true, uniqueness: true
  validates :display_language, inclusion: { in: DISPLAY_LANGUAGES }, allow_nil: true

  def current_consent
    Consent.find_by(pseudonym: pseudonym, document_version: Consent::CURRENT_VERSION)
  end

  def completed_scenario_keys
    conversations.counted.includes(:scenario).select(&:all_goals_met?).map { _1.scenario.key }.uniq
  end

  private

  def assign_pseudonym
    self.pseudonym ||= "learner-#{SecureRandom.hex(4)}"
  end
end
