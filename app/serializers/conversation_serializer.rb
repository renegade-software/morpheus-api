class ConversationSerializer
  def initialize(conversation)
    @conversation = conversation
  end

  AUDIO_LINK_TTL = 1.hour

  def as_json(*)
    scenario = @conversation.scenario
    {
      id: @conversation.id,
      scenario: scenario.key,
      mode: scenario.mode,
      status: @conversation.status,
      finished_reason: @conversation.finished_reason,
      turn_limit: scenario.turn_limit,
      extra_turns: scenario.extra_turns,
      turns: @conversation.turns.with_attached_audio.map { turn(_1) },
      goals: @conversation.goals,
      xp: (Xp.for(@conversation) unless @conversation.active?)
    }
  end

  private

  def turn(turn)
    { speaker: turn.speaker, text: turn.text, sent_at: turn.created_at, audio_url: audio_url(turn) }
  end

  def audio_url(turn)
    audio = turn.position.zero? ? @conversation.scenario.opening_audio : turn.audio
    AudioLink.url(audio, expires_in: AUDIO_LINK_TTL) if audio.attached?
  end
end
