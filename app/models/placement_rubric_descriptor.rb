class PlacementRubricDescriptor < ApplicationRecord
  include FrozenWithPlacementForm

  SKILLS = %w[writing speaking].freeze

  belongs_to :placement_form

  validates :skill, inclusion: { in: SKILLS }
  validates :criterion, :text, :source, presence: true
  validates :level, inclusion: { in: CefrLevel::RANGE }, uniqueness: { scope: [ :placement_form_id, :skill, :criterion ] }
end
