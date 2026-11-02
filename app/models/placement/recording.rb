module Placement
  class Recording < ApplicationRecord
    LEVEL_COLUMNS = %i[range_level accuracy_level fluency_level coherence_level overall_level].freeze

    belongs_to :attempt, foreign_key: :placement_attempt_id
    belongs_to :speaking_task, foreign_key: :placement_speaking_task_id

    belongs_to :evaluation_trace, optional: true

    has_one_attached :audio

    validates :placement_attempt_id, uniqueness: true
    validates(*LEVEL_COLUMNS, inclusion: { in: CefrLevel::RANGE }, allow_nil: true)

    def rated?
      overall_level.present?
    end
  end
end
