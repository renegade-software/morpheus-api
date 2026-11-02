module Conversation::TakeVoiceTurn
  MAX_BYTES = 10.megabytes
  AUDIO_LINK_TTL = 5.minutes

  def self.call(conversation, audio)
    position = conversation.turns.last.position + 1
    note = ActiveStorage::Blob.create_and_upload!(io: audio, filename: audio.original_filename,
                                                  content_type: audio.content_type)
    result = save(conversation, position, note, Agent.take_voice_turn(payload(conversation, note)))
    note.purge_later unless result == :ok
    result
  rescue StandardError
    note&.purge_later
    raise
  end

  def self.payload(conversation, note)
    content = conversation.scenario.content
    { scenario: content.fetch("scenario"), interlocutor: content.fetch("interlocutor"),
      turns: conversation.turns.map { { speaker: _1.speaker, text: _1.text } },
      audio_url: AudioLink.url(note, expires_in: AUDIO_LINK_TTL),
      voice_id: content.fetch("character").fetch("voice") }
  end

  def self.save(conversation, position, note, response)
    Conversation.transaction do
      traces = response.fetch("traces").map { Conversation::TakeTurn.create_trace(conversation, _1) }
      next response.fetch("status").to_sym unless response.fetch("status") == "ok"

      learner = conversation.turns.create!(position: position, speaker: "learner",
                                           text: response.fetch("transcript"), words: response.fetch("words"))
      learner.audio.attach(note)
      reply = conversation.turns.create!(position: position + 1, speaker: "character", text: response.fetch("reply"),
                                         evaluation_trace: traces.reverse.find { _1.step == "character_turn" })
      reply.audio.attach(io: StringIO.new(Base64.strict_decode64(response.fetch("reply_audio"))),
                         filename: "turn-#{position + 1}.mp3", content_type: response.fetch("reply_audio_type"))
      conversation.update!(goals: Conversation.merge_goals(conversation.goals, response.fetch("goals")))
      Conversation::TakeTurn.finish(conversation) if response.fetch("closed") || conversation.all_goals_met?
      :ok
    end
  end
end
