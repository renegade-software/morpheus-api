module Placement
  class AttemptsController < ApplicationController
    before_action :require_eligible_consent!

    # Starts the test, or resumes it: there is one attempt per learner, so a second POST returns the same one.
    def create
      existing = current_participant.placement_attempt
      return render json: StepSerializer.new(existing) if existing

      form = PlacementForm.current
      return render json: { errors: [ "no active placement form" ] }, status: :service_unavailable unless form

      attempt = current_participant.create_placement_attempt!(
        placement_form: form,
        current_step: Steps::FIRST,
        started_at: Time.current
      )
      render json: StepSerializer.new(attempt), status: :created
    end

    def show
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt

      render json: StepSerializer.new(attempt)
    end

    def start
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      return head :conflict unless params.expect(:step) == attempt.current_step

      attempt.update!(step_started_at: Time.current) if attempt.step_started_at.nil?
      render json: StepSerializer.new(attempt)
    end

    def play
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      return head :conflict unless params.expect(:step) == attempt.current_step

      passage = Steps.passage(attempt)
      return head :unprocessable_content unless passage.section == "listening"

      counted = attempt.with_lock do
        next false if attempt.plays_used >= passage.plays

        attempt.update!(plays_used: attempt.plays_used + 1, step_started_at: attempt.step_started_at || Time.current)
      end
      return head :unprocessable_content unless counted

      render json: StepSerializer.new(attempt)
    end

    def retake
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      return head :conflict unless attempt.current_step == "speaking" && params.expect(:step) == attempt.current_step

      task = Steps.speaking_task(attempt)
      counted = attempt.with_lock do
        next false if attempt.retakes_used >= task.retakes

        attempt.update!(retakes_used: attempt.retakes_used + 1, step_started_at: Time.current - task.prep_seconds)
      end
      return head :unprocessable_content unless counted

      render json: StepSerializer.new(attempt)
    end
  end
end
