class ConsentsController < ApplicationController
  def create
    return head :conflict if current_participant.current_consent

    consent = Consent.new(consent_params.merge(
      pseudonym: current_participant.pseudonym,
      document_version: Consent::CURRENT_VERSION,
      accepted_at: Time.current
    ))

    if consent.save
      render json: { eligible: consent.eligible?, voice_allowed: consent.voice_allowed? }, status: :created
    else
      render json: { errors: consent.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def consent_params
    params.expect(consent: Consent::QUESTIONS)
  end
end
