class UsersController < ApplicationController
  before_action :require_eligible_consent!, only: :update

  def show
    render json: user_json
  end

  def update
    if current_participant.update(user_params)
      render json: user_json
    else
      render json: { errors: current_participant.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(user: [ :display_language ])
  end

  def user_json
    consent = current_participant.current_consent

    {
      user_id: clerk.user_id,
      pseudonym: current_participant.pseudonym,
      display_language: current_participant.display_language,
      consent: consent && { eligible: consent.eligible?, voice_allowed: consent.voice_allowed? }
    }
  end
end
