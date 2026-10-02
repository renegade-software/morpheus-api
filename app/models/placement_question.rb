class PlacementQuestion < ApplicationRecord
  include FrozenWithPlacementForm

  belongs_to :placement_passage
  has_many :placement_responses, dependent: :restrict_with_exception
  delegate :placement_form, :section, :tier, to: :placement_passage

  validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :placement_passage_id }
  validates :prompt, presence: true
  validates :options, length: { is: 3 }
  validates :correct_option, inclusion: { in: 0..2 }
end
