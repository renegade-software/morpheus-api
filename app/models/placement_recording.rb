class PlacementRecording < ApplicationRecord
  PROMPT_IDS = %w[a b c].freeze
  LEVEL_COLUMNS = %i[range_level accuracy_level fluency_level coherence_level overall_level].freeze

  belongs_to :placement_attempt

  # Points at the call whose rating was accepted; nil until the recording is rated.
  belongs_to :evaluation_trace, optional: true

  # Private S3 bucket; Active Storage's tables arrive with S3 in iteration 3b. Destroying the record purges the file.
  has_one_attached :audio

  validates :placement_attempt_id, uniqueness: true
  validates :prompt_id, inclusion: { in: PROMPT_IDS }
  validates :submitted_at, presence: true
  validates(*LEVEL_COLUMNS, inclusion: { in: CefrLevel::RANGE }, allow_nil: true)

  def rated?
    overall_level.present?
  end
end
