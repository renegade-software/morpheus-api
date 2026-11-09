class Consent < ApplicationRecord
  QUESTIONS = %i[adult participate personal_data sensitive_data audio_recording transcription receive_results].freeze
  CURRENT_VERSION = "1.1".freeze

  # The signed copy is an ethics record, kept after the study's data is deleted, so destroying the row leaves it in
  # storage. Deleting one is done by hand.
  has_one_attached :pdf, dependent: false

  after_create_commit { ArchiveConsentJob.perform_later(self) }

  validates :pseudonym, :document_version, :accepted_at, presence: true
  validates(*QUESTIONS, inclusion: { in: [ true, false ] })
  validate :voice_requires_sensitive_data

  def eligible?
    adult && participate && personal_data
  end

  def voice_allowed?
    audio_recording && transcription
  end

  # Readable in the S3 console: consent/learner-0a1e35bf/v1.1-20261109T143005Z.pdf. UTC, without colons.
  def pdf_key
    "consent/#{pseudonym}/v#{document_version}-#{accepted_at.utc.strftime('%Y%m%dT%H%M%SZ')}.pdf"
  end

  private

  def voice_requires_sensitive_data
    return if sensitive_data
    return unless audio_recording || transcription

    errors.add(:sensitive_data, "must be authorized for audio recording or transcription")
  end
end
