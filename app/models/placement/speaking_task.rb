module Placement
  class SpeakingTask < ApplicationRecord
    include FrozenWithPlacementForm

    belongs_to :form, foreign_key: :placement_form_id
    has_many :speaking_anchors, -> { order(:level) }, foreign_key: :placement_speaking_task_id, dependent: :destroy

    validates :tier, inclusion: { in: Passage::TIERS }, uniqueness: { scope: :placement_form_id }
    validates :prompt, :seconds, presence: true

    def self.for_reading_result(reading_result)
      where("? = ANY(reading_results)", reading_result).first!
    end
  end
end
