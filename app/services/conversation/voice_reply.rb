# The second half of a voice turn: the character answers the learner's transcribed note, in the character's voice.
module Conversation::VoiceReply
  def self.call(conversation)
    response = Agent.voice_reply(payload(conversation))

    Conversation.transaction do
      traces = response.fetch("traces").map { Conversation::TakeTurn.create_trace(conversation, _1) }
      next :failed_checks unless response.fetch("status") == "ok"

      reply = conversation.turns.create!(position: conversation.turns.last.position + 1, speaker: "character",
                                         text: response.fetch("reply"),
                                         evaluation_trace: traces.reverse.find { _1.step == "character_turn" })
      reply.audio.attach(io: StringIO.new(Base64.strict_decode64(response.fetch("reply_audio"))),
                         filename: "turn-#{reply.position}.mp3", content_type: response.fetch("reply_audio_type"))
      conversation.update!(goals: Conversation.merge_goals(conversation.goals, response.fetch("goals")))
      Conversation::TakeTurn.finish(conversation) if response.fetch("closed") || conversation.all_goals_met?
      :ok
    end
  end

  def self.payload(conversation)
    content = conversation.scenario.content
    { scenario: content.fetch("scenario"), interlocutor: content.fetch("interlocutor"),
      turns: conversation.turns.map { { speaker: _1.speaker, text: _1.text } },
      voice_id: content.fetch("character").fetch("voice") }
  end
end
