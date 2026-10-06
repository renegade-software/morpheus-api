module Placement
  class WritingAnchor < ApplicationRecord
    include FrozenWithPlacementForm

    belongs_to :writing_task, foreign_key: :placement_writing_task_id
    delegate :form, to: :writing_task

    validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: :placement_writing_task_id }
    validates :text, :note, presence: true
  end
end
