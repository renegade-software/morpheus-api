class PlacementWritingAnchor < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_writing_task
  delegate :placement_form, to: :placement_writing_task

  validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: :placement_writing_task_id }
  validates :text, :note, presence: true
end
