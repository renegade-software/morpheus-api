module Placement
  class Attempt < ApplicationRecord
    STATUSES = %w[in_progress scoring completed failed].freeze
    TIER_RESULTS = 0..3

    belongs_to :participant
    belongs_to :form, foreign_key: :placement_form_id
    has_many :responses, foreign_key: :placement_attempt_id, dependent: :destroy
    has_one :writing, foreign_key: :placement_attempt_id, dependent: :destroy
    has_one :recording, foreign_key: :placement_attempt_id, dependent: :destroy
    # After writing and recording: they point at traces, so they're destroyed before the traces are.
    has_many :evaluation_traces, foreign_key: :placement_attempt_id, dependent: :destroy

    validates :participant_id, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :started_at, presence: true
    validates :reading_result, :listening_result, inclusion: { in: TIER_RESULTS }, allow_nil: true
    validates :writing_level, :speaking_level, :level_low, :level_high, inclusion: { in: CefrLevel::RANGE }, allow_nil: true

    # This is to render the level range the learner placed in
    def range_label
      return unless level_low && level_high

      "#{CefrLevel.label(level_low)}–#{CefrLevel.label(level_high)}"
    end
  end
end
