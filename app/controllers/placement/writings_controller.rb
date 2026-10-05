module Placement
  class WritingsController < ApplicationController
    before_action :require_eligible_consent!

    # Saves the learner's message, once: when they send it, or when the browser's clock runs out (`timed_out`, which
    # only the browser can see). The text reaches the server only here; drafts stay in the browser. An empty message
    # is kept too, so a time-out with nothing written is still on record. Rating it with Claude comes in 3b.
    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      # A stale tab sending after the attempt moved on would otherwise save a second message.
      return head :conflict unless attempt.current_step == "writing" && params.expect(:step) == attempt.current_step

      PlacementAttempt.transaction do
        attempt.create_placement_writing!(
          placement_writing_task: Steps.writing_task(attempt),
          text: params[:text].to_s,
          timed_out: ActiveModel::Type::Boolean.new.cast(params[:timed_out]) || false
        )
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepSerializer.new(attempt), status: :created
    end
  end
end
