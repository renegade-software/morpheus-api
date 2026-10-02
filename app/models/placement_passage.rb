class PlacementPassage < ApplicationRecord
  include FrozenWithPlacementForm

  SECTIONS = %w[reading listening].freeze
  TIERS = %w[a b c].freeze

  belongs_to :placement_form
  has_many :placement_questions, -> { order(:position) }, dependent: :destroy
  # Listening only. Attach it before the form is activated; after that the passage is read-only.
  has_one_attached :audio

  validates :section, inclusion: { in: SECTIONS }
  validates :tier, inclusion: { in: TIERS }, uniqueness: { scope: [ :placement_form_id, :section ] }
  validates :level, inclusion: { in: CefrLevel::RANGE }
  validates :cefr_scale, :cefr_descriptor, presence: true
  validates :seconds, presence: true
  validates :body, presence: true, if: -> { section == "reading" }
  validates :transcript, :plays, presence: true, if: -> { section == "listening" }
end
