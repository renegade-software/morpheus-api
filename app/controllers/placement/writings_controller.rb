module Placement
  class WritingsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      attempt = current_participant.placement_attempt
      return head :not_found unless attempt
      return head :conflict unless attempt.current_step == "writing" && params.expect(:step) == attempt.current_step

      Attempt.transaction do
        writing = attempt.create_writing!(
          writing_task: Steps.writing_task(attempt),
          text: params[:text].to_s,
          timed_out: ActiveModel::Type::Boolean.new.cast(params[:timed_out]) || false
        )
        # Rated while the learner does the speaking part. The job row is part of this transaction (Solid Queue shares
        # the database), so it only exists, and only runs, once the writing does.
        ScoreWritingJob.perform_later(writing)
        Steps.advance!(attempt)
        attempt.save!
      end

      render json: StepSerializer.new(attempt), status: :created
    end
  end
end
