class PlacementWritingTask < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_form
  has_many :placement_writing_anchors, -> { order(:level) }, dependent: :destroy

  validates :placement_form_id, uniqueness: true
  validates :prompt, :seconds, presence: true
end
