module Placement
  class SpeakingAnchor < ApplicationRecord
    include FrozenWithPlacementForm

    belongs_to :speaking_task, foreign_key: :placement_speaking_task_id
    delegate :form, to: :speaking_task

    validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: :placement_speaking_task_id }
    validates :transcript, :note, :speaking_ms, :word_count, :long_pauses, presence: true
  end
end
