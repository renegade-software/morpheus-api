class PlacementWriting < ApplicationRecord
  LEVEL_COLUMNS = %i[production_level range_level accuracy_level coherence_level overall_level].freeze

  belongs_to :placement_attempt
  belongs_to :placement_task
  # Points at the call whose rating was accepted; nil until the writing is rated.
  belongs_to :evaluation_trace, optional: true

  validates :placement_attempt_id, uniqueness: true
  validates :submitted_at, presence: true
  validates(*LEVEL_COLUMNS, inclusion: { in: CefrLevel::RANGE }, allow_nil: true)

  def rated?
    overall_level.present?
  end
end
