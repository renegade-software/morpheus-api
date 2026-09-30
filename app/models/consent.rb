class Consent < ApplicationRecord
  QUESTIONS = %i[adult participate personal_data sensitive_data audio_recording transcription receive_results].freeze
  CURRENT_VERSION = "1.0".freeze

  validates :pseudonym, :document_version, :accepted_at, presence: true
  validates(*QUESTIONS, inclusion: { in: [ true, false ] })
  validate :voice_requires_sensitive_data

  def eligible?
    adult && participate && personal_data
  end

  def voice_allowed?
    audio_recording && transcription
  end

  private

  def voice_requires_sensitive_data
    return if sensitive_data
    return unless audio_recording || transcription

    errors.add(:sensitive_data, "must be authorized for audio recording or transcription")
  end
end
