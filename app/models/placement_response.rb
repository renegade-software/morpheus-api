class PlacementResponse < ApplicationRecord
  belongs_to :placement_attempt
  belongs_to :placement_question
  delegate :section, :tier, to: :placement_question

  validates :placement_question_id, uniqueness: { scope: :placement_attempt_id }
  validates :selected_option, inclusion: { in: 0..2 }, allow_nil: true
  validates :correct, inclusion: { in: [ true, false ] }
  validates :shown_at, presence: true

  # The browser runs the timers; a question left unanswered when time ran out arrives with no option.
  def timed_out?
    selected_option.nil?
  end
end
