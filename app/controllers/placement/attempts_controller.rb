module Placement
  class AttemptsController < ApplicationController
    include PlacementPurpose

    before_action :require_eligible_consent!

    def create
      existing = placement_attempt
      return render json: StepSerializer.new(existing) if existing

      if final_placement? && current_participant.placement_attempt&.status != "completed"
        return render json: { errors: [ "the final test opens once the first one is done" ] }, status: :conflict
      end

      form = Form.current(final_placement? ? "final" : "intake")
      return render json: { errors: [ "no active placement form" ] }, status: :service_unavailable unless form

      attempt = new_attempt(form)
      render json: StepSerializer.new(attempt), status: :created
    end

    # GET /placement/attempts: both tests for the Pruebas tab, null where one hasn't been started.
    def index
      intake = current_participant.placement_attempt
      render json: {
        intake: summary(intake),
        final: summary(current_participant.final_placement_attempt),
        final_available: intake&.status == "completed" && Form.current("final").present?
      }
    end

    def show
      attempt = placement_attempt
      return head :not_found unless attempt

      render json: StepSerializer.new(attempt)
    end

    def start
      attempt = placement_attempt
      return head :not_found unless attempt
      return head :conflict unless params.expect(:step) == attempt.current_step

      attempt.update!(step_started_at: Time.current) if attempt.step_started_at.nil?
      render json: StepSerializer.new(attempt)
    end

    def play
      attempt = placement_attempt
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
      attempt = placement_attempt
      return head :not_found unless attempt
      return head :conflict unless attempt.current_step == "speaking" && params.expect(:step) == attempt.current_step

      task = Steps.speaking_task(attempt)
      counted = attempt.with_lock do
        next false if attempt.retakes_used >= task.retakes

        attempt.update!(retakes_used: attempt.retakes_used + 1, step_started_at: Time.current)
      end
      return head :unprocessable_content unless counted

      render json: StepSerializer.new(attempt)
    end

    private

    def new_attempt(form)
      attributes = { form: form, current_step: Steps::FIRST, started_at: Time.current }
      return current_participant.create_final_placement_attempt!(attributes) if final_placement?

      current_participant.create_placement_attempt!(attributes)
    end

    # Reading and listening are texts passed out of 3; writing and speaking are CEFR levels (A1 = 0), speaking null
    # for learners who didn't consent to voice.
    def summary(attempt)
      return unless attempt

      attempt.slice(:status, :started_at, :completed_at, :level_low, :level_high, :reading_result,
                    :listening_result, :writing_level, :speaking_level)
    end
  end
end
