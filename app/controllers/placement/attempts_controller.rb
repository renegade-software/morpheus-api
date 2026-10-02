module Placement
  class AttemptsController < ApplicationController
    before_action :require_eligible_consent!

    # Starts the test, or resumes it: there is one attempt per learner, so a second POST returns the same one.
    def create
      existing = current_participant.placement_attempt
      return render json: StepPresenter.new(existing) if existing

      attempt = current_participant.create_placement_attempt!(
        content_version: Content.version,
        current_step: Steps::FIRST,
        started_at: Time.current
      )
      render json: StepPresenter.new(attempt), status: :created
    end

    def show
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt

      render json: StepPresenter.new(attempt)
    end
  end
end
