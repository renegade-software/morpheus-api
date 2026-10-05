module Placement
  class ResponsesController < ApplicationController
    before_action :require_eligible_consent!

    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      # A stale tab submitting a step that's already done would otherwise overwrite nothing and confuse the sequence.
      return head :conflict unless params.expect(:step) == attempt.current_step

      answers = params.expect(answers: [ [ :question_id, :selected_option ] ])
      open_questions = Steps.unanswered_questions(attempt).index_by(&:id)
      question_ids = answers.map { Integer(_1[:question_id]) }
      if question_ids.empty? || question_ids.uniq.size < question_ids.size || (question_ids - open_questions.keys).any?
        return render json: { errors: [ "answers must be for unanswered questions #{open_questions.keys.join(', ')}" ] },
                      status: :unprocessable_content
      end

      PlacementAttempt.transaction do
        answers.each { |answer| record_response(attempt, open_questions.fetch(Integer(answer[:question_id])), answer) }
        if Steps.unanswered_questions(attempt).none?
          Steps.advance!(attempt)
          attempt.save!
        end
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
