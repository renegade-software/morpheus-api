module Placement
  class WritingTask < ApplicationRecord
    include FrozenWithPlacementForm

    belongs_to :form, foreign_key: :placement_form_id
    has_many :writing_anchors, -> { order(:level) }, foreign_key: :placement_writing_task_id, dependent: :destroy

    validates :placement_form_id, uniqueness: true
    validates :prompt, :seconds, presence: true
  end
end
