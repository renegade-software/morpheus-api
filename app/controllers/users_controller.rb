class UsersController < ApplicationController
  def show
    consent = current_participant.current_consent

    render json: {
      user_id: clerk.user_id,
      pseudonym: current_participant.pseudonym,
      consent: consent && { eligible: consent.eligible?, voice_allowed: consent.voice_allowed? }
    }
  end
end
