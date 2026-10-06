module Placement
  class Question < ApplicationRecord
    include FrozenWithPlacementForm

    belongs_to :passage, foreign_key: :placement_passage_id
    has_many :responses, foreign_key: :placement_question_id, dependent: :restrict_with_exception
    delegate :form, :section, :tier, to: :passage

    validates :position, numericality: { only_integer: true, greater_than: 0 }, uniqueness: { scope: :placement_passage_id }
    validates :prompt, presence: true
    validates :options, length: { is: 3 }
    validates :correct_option, inclusion: { in: 0..2 }
  end
end
