class StageReviewsController < ApplicationController
  before_action :require_eligible_consent!
  before_action :require_known_stage!
  before_action :require_reached!

  # GET /stage_reviews/:stage?scenarios=a,b,c
  # The UI sends the scenario keys that come before the review on that stage's path.
  def show
    review = current_participant.stage_reviews.find_by(stage: stage)
    render json: {
      stage: stage,
      points: StageReview::POINTS,
      acknowledged: review.present?,
      groups: StageReview.mistakes(current_participant, scenario_keys)
    }
  end

  # POST /stage_reviews/:stage/acknowledge
  def acknowledge
    review = StageReview.acknowledge!(current_participant, stage)
    # A second press (double click, retry) finds the existing row and earns nothing more.
    earned = review.previously_new_record? ? StageReview::POINTS : 0
    total = Xp.summary(current_participant).fetch(:total)
    render json: { stage: stage, xp: { earned: earned, total_before: total - earned, total_after: total } }
  end

  private

  def stage
    params.expect(:stage)
  end

  def scenario_keys
    params.fetch(:scenarios, "").split(",").map(&:strip).compact_blank
  end

  def require_known_stage!
    head :not_found unless StageReview::STAGES.include?(stage)
  end

  def require_reached!
    head :forbidden unless LearningPath.can_review?(current_participant, stage)
  end
end
