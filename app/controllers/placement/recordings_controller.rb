module Placement
  class RecordingsController < ApplicationController
    before_action :require_eligible_consent!

    # Saves the learner's spoken answer, once: the audio file, whether the browser's clock ran out (`timed_out`, which
    # only the browser can see) and what the browser asked for versus got when recording (`capture_metadata`, JSON).
    # That ends the test. The audio can be missing (time ran out before anything was recorded, say after a long absence),
    # and the recording row is kept anyway, like an empty writing. Transcribing and rating it comes in 3b.
    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      # A stale tab sending after the attempt moved on would otherwise save a second recording.
      return head :conflict unless attempt.current_step == "speaking" && params.expect(:step) == attempt.current_step
      return head :forbidden unless current_participant.current_consent&.voice_allowed?

      PlacementAttempt.transaction do
        recording = attempt.create_placement_recording!(
          placement_speaking_task: Steps.speaking_task(attempt),
          timed_out: ActiveModel::Type::Boolean.new.cast(params[:timed_out]) || false,
          capture_metadata: capture_metadata
        )

        Rails.logger.debug "#################### recording.audio.inspect #{recording.audio.inspect}"

        recording.audio.attach(params[:audio]) if params[:audio].present?
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepSerializer.new(attempt), status: :created
    end

    private

    # Sent as a JSON string inside the multipart form; kept as given, or nil if it doesn't parse.
    def capture_metadata
      JSON.parse(params[:capture_metadata].to_s)
    rescue JSON::ParserError
      nil
    end
  end
end
