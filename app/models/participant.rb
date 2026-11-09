class Participant < ApplicationRecord
  DISPLAY_LANGUAGES = %w[en es].freeze

  before_validation :assign_pseudonym, on: :create

  # The intake test, which sets the level, the first stage and the rank points. The final test only reports a result.
  has_one :placement_attempt, -> { where(purpose: "intake") }, class_name: "Placement::Attempt", dependent: :destroy
  has_one :final_placement_attempt, -> { where(purpose: "final") }, class_name: "Placement::Attempt",
                                                                     dependent: :destroy
  has_many :conversations, dependent: :destroy
  has_many :evaluation_traces, dependent: :destroy
  has_many :stage_reviews, dependent: :destroy
  has_many :perception_responses, dependent: :destroy
  has_many :stage_quiz_attempts, dependent: :destroy

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :pseudonym, presence: true, uniqueness: true
  validates :display_language, inclusion: { in: DISPLAY_LANGUAGES }, allow_nil: true
  validates :current_stage, inclusion: { in: Stage::KEYS }, allow_nil: true

  # Until the learner first moves up, the first stage of their placement level.
  def stage
    return current_stage if current_stage

    level = placement_attempt&.level_low
    level && Stage.first_for(level)
  end

  # Moving on needs the stage's last checkpoint: its quiz passed or, at C2 where there's no quiz, its review done.
  def stage_finished?(key)
    return stage_quiz_attempts.passed.exists?(stage: key) if StageQuiz.questions(key)

    stage_reviews.exists?(stage: key)
  end

  # `from` guards against a double press moving the learner two stages.
  def advance_stage!(from)
    following = Stage.after(from) if from == stage
    return false unless following && stage_finished?(from)

    # current_level stays what the placement test measured: passing a stage's grammar quiz isn't a CEFR measurement.
    update!(current_stage: following)
  end

  def current_consent
    Consent.find_by(pseudonym: pseudonym, document_version: Consent::CURRENT_VERSION)
  end

  def completed_scenario_keys
    conversations.counted.includes(:scenario).select(&:advances_path?).map { _1.scenario.key }.uniq
  end

  private

  def assign_pseudonym
    self.pseudonym ||= "learner-#{SecureRandom.hex(4)}"
  end
end
