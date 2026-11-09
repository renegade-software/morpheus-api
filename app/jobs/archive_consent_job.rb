# Keeps the signed consent as a PDF in storage (S3 in production), the record the document promises to keep after the
# study's data is deleted. Runs after signing so the participant never waits on Clerk or S3.
class ArchiveConsentJob < ApplicationJob
  # Without the participant there's no Clerk user to read the email from, so retrying can't help.
  class MissingParticipant < StandardError; end

  # Clerk or S3 being down for a few hours shouldn't lose a record: ten tries spread over roughly four hours.
  retry_on StandardError, wait: :polynomially_longer, attempts: 10 do |job, error|
    Rails.logger.error("consent #{job.arguments.first.id} not archived: #{error.class}: #{error.message}")
  end
  discard_on MissingParticipant do |job, _error|
    Rails.logger.error("consent #{job.arguments.first.id} not archived: no participant #{job.arguments.first.pseudonym}")
  end
  discard_on ActiveJob::DeserializationError

  def perform(consent)
    return if consent.pdf.attached?

    pdf = ConsentPdf.render(consent, email: email(consent))
    consent.pdf.attach(io: StringIO.new(pdf), key: consent.pdf_key, filename: File.basename(consent.pdf_key),
                       content_type: "application/pdf", identify: false)
  end

  private

  # Unlike the download, a missing email raises: a stored record should say who signed it.
  def email(consent)
    participant = Participant.find_by(pseudonym: consent.pseudonym)
    raise MissingParticipant unless participant

    # The job's own retries wait between tries; the SDK's would hold a worker thread for up to an hour.
    user = Clerk::SDK.new.users.get(user_id: participant.clerk_user_id,
                                    retries: Clerk::Utils::RetryConfig.new(strategy: "none")).user
    address = user.email_addresses.find { _1.id == user.primary_email_address_id }&.email_address
    return address if address

    raise "Clerk user #{participant.clerk_user_id} has no primary email"
  end
end
