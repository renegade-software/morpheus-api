# One skill's score (FR9). A nil score is "not enough evidence", never a low one.
class Feedback::Score < ApplicationRecord
  belongs_to :feedback

  validates :skill, :reason, presence: true
  validates :score, inclusion: { in: 1..5 }, allow_nil: true
end
