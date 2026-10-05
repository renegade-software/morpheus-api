module Placement
  class RecordingsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      return head :conflict unless attempt.current_step == "speaking" && params.expect(:step) == attempt.current_step
      return head :forbidden unless current_participant.current_consent&.voice_allowed?

      PlacementAttempt.transaction do
        recording = attempt.create_placement_recording!(
          placement_speaking_task: Steps.speaking_task(attempt),
          timed_out: ActiveModel::Type::Boolean.new.cast(params[:timed_out]) || false,
          capture_metadata: capture_metadata
        )
        recording.audio.attach(params[:audio]) if params[:audio].present?
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepSerializer.new(attempt), status: :created
    end

    private

    def capture_metadata
      JSON.parse(params[:capture_metadata].to_s)
    rescue JSON::ParserError
      nil
    end
  end
end
