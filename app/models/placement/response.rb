module Placement
  class Response < ApplicationRecord
    belongs_to :attempt, foreign_key: :placement_attempt_id
    belongs_to :question, foreign_key: :placement_question_id
    delegate :section, :tier, to: :question

    validates :placement_question_id, uniqueness: { scope: :placement_attempt_id }
    validates :selected_option, inclusion: { in: 0..2 }, allow_nil: true
    validates :correct, inclusion: { in: [ true, false ] }

    # The browser runs the timers; a question left unanswered when time ran out arrives with no option.
    def timed_out?
      selected_option.nil?
    end
  end
end
