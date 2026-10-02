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

      answers = params.expect(answers: [ [ :item_key, :selected_option, :shown_at, :answered_at ] ])
      expected_keys = Steps.item_keys(attempt.current_step)
      unless answers.map { _1[:item_key] }.sort == expected_keys.sort
        return render json: { errors: [ "answers must cover #{expected_keys.join(', ')}" ] }, status: :unprocessable_content
      end

      PlacementAttempt.transaction do
        answers.each { |answer| record_response(attempt, answer) }
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepPresenter.new(attempt)
    end

    private

    def record_response(attempt, answer)
      selected_option = answer[:selected_option].presence&.then { Integer(_1) }
      attempt.placement_responses.create!(
        section: answer[:item_key].split(".").first,
        item_key: answer[:item_key],
        selected_option: selected_option,
        correct: selected_option == Content.question(answer[:item_key]).fetch("answer"),
        shown_at: answer[:shown_at],
        answered_at: answer[:answered_at]
      )
    end
  end
end
