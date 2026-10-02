class PlacementAnchor < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_task
  delegate :placement_form, to: :placement_task

  validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: :placement_task_id }
  validates :text, :note, presence: true
end
