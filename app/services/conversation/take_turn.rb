module Conversation::TakeTurn
  MAX_TEXT = 1_000
  MAX_WRITING = 2_000

  def self.max_length(conversation)
    conversation.writing? ? MAX_WRITING : MAX_TEXT
  end

  def self.call(conversation, text)
    position = conversation.turns.last.position + 1
    response = Agent.take_turn(payload(conversation, text))

    Conversation.transaction do
      traces = response.fetch("traces").map { create_trace(conversation, _1) }
      next :failed_checks unless response.fetch("status") == "ok"

      conversation.turns.create!(position: position, speaker: "learner", text: text)
      reply = response["reply"]
      if reply.present?
        conversation.turns.create!(position: position + 1, speaker: "character", text: reply,
                                   evaluation_trace: traces.last)
      end
      conversation.update!(goals: Conversation.merge_goals(conversation.goals, response.fetch("goals")))
      finish(conversation) if conversation.writing? || response.fetch("closed") || conversation.all_goals_met?
      :ok
    end
  end

  def self.payload(conversation, text)
    content = conversation.scenario.content
    turns = conversation.turns.map { { speaker: _1.speaker, text: _1.text } }
    # The character's prompt names the medium, so a voice scenario played as a typed chat is sent as text.
    { scenario: content.fetch("scenario").merge("mode" => conversation.mode), interlocutor: content.fetch("interlocutor"),
      turns: turns + [ { speaker: "learner", text: text } ] }
  end

  # A conversation the character closed before the turn limit with goals still open ended on a goodbye the learner
  # asked for ("that'll be all"), so it counts as ended by the learner.
  def self.finish(conversation)
    return conversation.finish!("goals_met") if conversation.all_goals_met?

    learner_turns = conversation.turns.where(speaker: "learner").count
    conversation.finish!(learner_turns < conversation.scenario.turn_limit ? "ended_by_learner" : "turn_limit")
  end

  def self.create_trace(conversation, trace)
    conversation.participant.evaluation_traces.create!(
      trace.slice(*EvaluationTrace::AGENT_FIELDS).merge("conversation" => conversation)
    )
  end
end
