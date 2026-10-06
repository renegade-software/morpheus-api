class PlacementRecording < ApplicationRecord
  LEVEL_COLUMNS = %i[range_level accuracy_level fluency_level coherence_level overall_level].freeze

  belongs_to :placement_attempt
  belongs_to :placement_speaking_task

  # Points at the call whose rating was accepted; nil until the recording is rated.
  belongs_to :evaluation_trace, optional: true

  # Private bucket (S3 from iteration 3b). Destroying the record purges the file.
  has_one_attached :audio

  validates :placement_attempt_id, uniqueness: true
  validates(*LEVEL_COLUMNS, inclusion: { in: CefrLevel::RANGE }, allow_nil: true)

  def rated?
    overall_level.present?
  end
end
