# A short-lived link to a stored recording, for the agent to download or the browser to play.
module AudioLink
  # S3 in production signs the link itself; local disk storage needs this server's address (development.rb).
  def self.url(attachable, expires_in:)
    ActiveStorage::Current.set(url_options: Rails.configuration.x.audio_url_options || {}) do
      attachable.url(expires_in: expires_in)
    end
  end
end
