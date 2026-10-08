# The body of POST /placement/speaking, built from the form the attempt is frozen to. Only the anchors for the
# learner's own prompt are sent. Reading, listening and writing results are left out, so they can't sway the rating.
module Placement::SpeakingPayload
  CRITERIA = %w[range accuracy fluency coherence].freeze
  # The agent downloads the audio straight away; the link only has to outlive one request.
  AUDIO_LINK_TTL = 5.minutes

  def self.build(recording)
    task = recording.speaking_task
    {
      audio_url: audio_url(recording),
      timed_out: recording.timed_out,
      task: { prompt: task.prompt, scoring_rules: task.scoring_rules },
      anchors: task.speaking_anchors.map { |anchor| anchor_fields(anchor) },
      rubric: rubric(task.form)
    }
  end

  # S3 in production signs the link itself; local disk storage needs this server's address (development.rb).
  def self.audio_url(recording)
    ActiveStorage::Current.set(url_options: Rails.configuration.x.audio_url_options || {}) do
      recording.audio.url(expires_in: AUDIO_LINK_TTL)
    end
  end

  def self.anchor_fields(anchor)
    anchor.slice(:level, :transcript, :note, :speaking_ms, :word_count, :long_pauses)
  end

  # Descriptors grouped by criterion, as the agent expects. A missing criterion raises, so a broken form fails loudly.
  def self.rubric(form)
    descriptors = form.rubric_descriptors.where(skill: "speaking").order(:level).group_by(&:criterion)
    CRITERIA.index_with { |criterion| descriptors.fetch(criterion).map { |d| { level: d.level, text: d.text } } }
  end
end
