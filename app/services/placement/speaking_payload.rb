module Placement::SpeakingPayload
  CRITERIA = %w[range accuracy fluency coherence].freeze
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

  def self.audio_url(recording)
    AudioLink.url(recording.audio, expires_in: AUDIO_LINK_TTL)
  end

  def self.anchor_fields(anchor)
    anchor.slice(:level, :transcript, :note, :speaking_ms, :word_count, :long_pauses)
  end

  def self.rubric(form)
    descriptors = form.rubric_descriptors.where(skill: "speaking").order(:level).group_by(&:criterion)
    CRITERIA.index_with { |criterion| descriptors.fetch(criterion).map { |d| { level: d.level, text: d.text } } }
  end
end
