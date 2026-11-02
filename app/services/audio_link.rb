module AudioLink
  def self.url(attachable, expires_in:)
    ActiveStorage::Current.set(url_options: Rails.configuration.x.audio_url_options || {}) do
      attachable.url(expires_in: expires_in)
    end
  end
end
