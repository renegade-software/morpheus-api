class ConsentsController < ApplicationController
  # GET /consent: the participant's own copy as a PDF, the one the document promises "en cualquier momento".
  def show
    consent = current_participant.current_consent
    return head :not_found unless consent

    pdf = ConsentPdf.render(consent, email: primary_email)
    send_data pdf, type: "application/pdf", disposition: "attachment", filename: "consentimiento-#{consent.pseudonym}.pdf"
  end

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

  # The participant's email, read from Clerk for this copy only. If Clerk can't be reached the copy still downloads,
  # with the email marked as unavailable.
  def primary_email
    user = clerk.user
    user.email_addresses.find { _1.id == user.primary_email_address_id }&.email_address
  rescue StandardError => error
    Rails.logger.warn("consent PDF without the Clerk email: #{error.class}: #{error.message}")
    nil
  end

  def consent_params
    params.expect(consent: Consent::QUESTIONS)
  end
end
