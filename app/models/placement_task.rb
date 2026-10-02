class PlacementTask < ApplicationRecord
  include FrozenWithPlacementForm

  KINDS = %w[writing speaking].freeze

  belongs_to :placement_form
  has_many :placement_anchors, -> { order(:level) }, dependent: :destroy

  scope :writing, -> { where(kind: "writing") }
  scope :speaking, -> { where(kind: "speaking") }

  validates :kind, inclusion: { in: KINDS }
  validates :tier, inclusion: { in: PlacementPassage::TIERS }, if: -> { kind == "speaking" }
  validates :prompt, :seconds, presence: true

  def self.for_reading_result(reading_result)
    speaking.where("? = ANY(reading_results)", reading_result).first!
  end
end
