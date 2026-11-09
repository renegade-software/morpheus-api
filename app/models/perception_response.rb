# One learner's answers to the perception questionnaire on a stage review, each 1 (strongly disagree) to 5
# (strongly agree), stored as given.
class PerceptionResponse < ApplicationRecord
  ITEMS = %i[robotic friendly easy_to_use complex_to_use good_solutions could_not_help useful_responses].freeze
  # Agreeing with these is a bad sign, so analysis flips them (6 - answer) before averaging.
  REVERSED = %i[robotic complex_to_use could_not_help].freeze

  belongs_to :participant

  validates :stage, inclusion: { in: Stage::KEYS }, uniqueness: { scope: :participant_id }
  validates(*ITEMS, inclusion: { in: 1..5 })
end
