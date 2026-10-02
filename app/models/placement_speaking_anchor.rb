class PlacementSpeakingAnchor < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_speaking_task
  delegate :placement_form, to: :placement_speaking_task

  validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: :placement_speaking_task_id }
  validates :transcript, :note, :speaking_seconds, presence: true
end
