# The first half of a voice turn: the learner's note becomes their turn as soon as it's transcribed, so they see their
# words while the character's reply (Conversation::VoiceReply) is still being written.
module Conversation::TakeVoiceTurn
  MAX_BYTES = 10.megabytes
  AUDIO_LINK_TTL = 5.minutes

  def self.call(conversation, audio)
    note = ActiveStorage::Blob.create_and_upload!(io: audio, filename: audio.original_filename,
                                                  content_type: audio.content_type)
    response = Agent.transcribe(audio_url: AudioLink.url(note, expires_in: AUDIO_LINK_TTL))
    result = save(conversation, note, response)
    note.purge_later unless result == :ok
    result
  rescue StandardError
    note&.purge_later
    raise
  end

  def self.save(conversation, note, response)
    Conversation.transaction do
      response.fetch("traces").each { Conversation::TakeTurn.create_trace(conversation, _1) }
      next :no_speech unless response.fetch("status") == "ok"

      learner = conversation.turns.create!(position: conversation.turns.last.position + 1, speaker: "learner",
                                           text: response.fetch("transcript"), words: response.fetch("words"))
      learner.audio.attach(note)
      :ok
    end
  end
end
