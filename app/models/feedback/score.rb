class Feedback::Score < ApplicationRecord
  belongs_to :feedback

  validates :skill, :reason, presence: true
  validates :score, inclusion: { in: 1..5 }, allow_nil: true
end
