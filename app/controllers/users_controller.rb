class UsersController < ApplicationController
  before_action :require_eligible_consent!, only: :update

  def show
    render json: user_json
  end

  def update
    current_participant.assign_attributes(user_params.except(:onboarded))
    # The app only says "done"; the server stamps when, and the first time stays.
    current_participant.onboarded_at ||= Time.current if onboarded?

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

  def onboarded?
    ActiveModel::Type::Boolean.new.cast(user_params[:onboarded])
  end

  def user_json
    consent = current_participant.current_consent

    {
      user_id: clerk.user_id,
      pseudonym: current_participant.pseudonym,
      display_language: current_participant.display_language,
      onboarded: current_participant.onboarded_at.present?,
      consent: consent && { eligible: consent.eligible?, voice_allowed: consent.voice_allowed? }
    }
  end
end
