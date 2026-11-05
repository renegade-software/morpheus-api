class UsersController < ApplicationController
  before_action :require_eligible_consent!, only: %i[update advance_stage]

  def show
    render json: user_json
  end

  # POST /user/advance_stage  { from: "firstSteps" }
  def advance_stage
    return head :conflict unless current_participant.advance_stage!(params.expect(:from))

    render json: user_json
  end

  def update
    current_participant.assign_attributes(user_params.except(:onboarded))
    apply_onboarded if user_params.key?(:onboarded)

    if current_participant.save
      render json: user_json
    else
      render json: { errors: current_participant.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: [ :display_language, :onboarded ])
  end

  def apply_onboarded
    if ActiveModel::Type::Boolean.new.cast(user_params[:onboarded])
      current_participant.onboarded_at ||= Time.current
    else
      current_participant.onboarded_at = nil
    end
  end

  def user_json
    consent = current_participant.current_consent

    {
      user_id: clerk.user_id,
      pseudonym: current_participant.pseudonym,
      display_language: current_participant.display_language,
      onboarded: current_participant.onboarded_at.present?,
      rank_points: current_participant.rank_points,
      current_stage: current_participant.stage,
      completed_scenarios: current_participant.completed_scenario_keys,
      completed_reviews: current_participant.stage_reviews.pluck(:stage),
      passed_quizzes: current_participant.stage_quiz_attempts.passed.distinct.pluck(:stage),
      xp: Xp.summary(current_participant),
      consent: consent && { eligible: consent.eligible?, voice_allowed: consent.voice_allowed? }
    }
  end
end
