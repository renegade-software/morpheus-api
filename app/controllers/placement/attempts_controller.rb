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
  end
end
