module Placement
  class ResponsesController < ApplicationController
    before_action :require_eligible_consent!

    # Saves one step's answers (both questions of a reading text, or one listening question), grades them against
    # the key and returns the next step. The browser runs the timers; a timed-out question arrives with no option.
    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      # A stale tab submitting a step that's already done would otherwise overwrite nothing and confuse the sequence.
      return head :conflict unless params.expect(:step) == attempt.current_step

      answers = params.expect(answers: [ [ :question_id, :selected_option ] ])
      questions = Steps.questions(attempt).index_by(&:id)
      unless answers.map { Integer(_1[:question_id]) }.sort == questions.keys.sort
        return render json: { errors: [ "answers must cover questions #{questions.keys.join(', ')}" ] },
                      status: :unprocessable_content
      end

      PlacementAttempt.transaction do
        answers.each { |answer| record_response(attempt, questions.fetch(Integer(answer[:question_id])), answer) }
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepSerializer.new(attempt)
    end

    private

    def record_response(attempt, question, answer)
      selected_option = answer[:selected_option].presence&.then { Integer(_1) }
      attempt.placement_responses.create!(
        placement_question: question,
        selected_option: selected_option,
        correct: selected_option == question.correct_option
      )
    end
  end
end
