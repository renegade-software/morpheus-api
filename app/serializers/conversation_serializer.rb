# What the conversation screen needs, picked by hand like the placement serializer: the transcript, the goal checks
# and where the turn limit stands. The scenario's agenda and the character's instructions stay on the server.
class ConversationSerializer
  def initialize(conversation)
    @conversation = conversation
  end

  # Long enough to replay a note while the chat is open; the next response carries fresh links.
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
      # Once it's over: what it earned, for the XP screen (null while active, or when it doesn't count).
      xp: (Xp.for(@conversation) unless @conversation.active?)
    }
  end

  private

  def turn(turn)
    { speaker: turn.speaker, text: turn.text, sent_at: turn.created_at, audio_url: audio_url(turn) }
  end

  # The opening is the scenario version's own recording; every later voice turn has its own.
  def audio_url(turn)
    audio = turn.position.zero? ? @conversation.scenario.opening_audio : turn.audio
    AudioLink.url(audio, expires_in: AUDIO_LINK_TTL) if audio.attached?
  end
end
