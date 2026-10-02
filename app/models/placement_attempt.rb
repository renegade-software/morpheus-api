class PlacementAttempt < ApplicationRecord
  STATUSES = %w[in_progress scoring completed failed].freeze
  TIER_RESULTS = 0..3

  belongs_to :participant
  has_many :placement_responses, dependent: :destroy
  has_one :placement_writing, dependent: :destroy
  has_one :placement_recording, dependent: :destroy

  validates :participant_id, uniqueness: true
  validates :status, inclusion: { in: STATUSES }
  validates :content_version, :started_at, presence: true
  validates :reading_result, :listening_result, inclusion: { in: TIER_RESULTS }, allow_nil: true
  validates :writing_level, :speaking_level, :level_low, :level_high, inclusion: { in: CefrLevel::RANGE }, allow_nil: true

  # This is to render the level range the learner placed in
  def range_label
    return unless level_low && level_high

    "#{CefrLevel.label(level_low)}–#{CefrLevel.label(level_high)}"
  end
end
