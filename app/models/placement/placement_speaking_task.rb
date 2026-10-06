class PlacementSpeakingTask < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_form
  has_many :placement_speaking_anchors, -> { order(:level) }, dependent: :destroy

  validates :tier, inclusion: { in: PlacementPassage::TIERS }, uniqueness: { scope: :placement_form_id }
  validates :prompt, :seconds, presence: true

  def self.for_reading_result(reading_result)
    where("? = ANY(reading_results)", reading_result).first!
  end
end
