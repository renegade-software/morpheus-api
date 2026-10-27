# One learner message and the character's answer. The agent is called before anything is saved, so a busy or failed
# call leaves the conversation as it was and the learner can send the same message again. Every call's traces are
# stored either way (NFR5).
module Conversation::TakeTurn
  MAX_TEXT = 1_000 # characters; a chat message, not an essay

  def self.call(conversation, text)
    position = conversation.turns.last.position + 1
    response = Agent.take_turn(payload(conversation, text))

    Conversation.transaction do
      traces = response.fetch("traces").map { create_trace(conversation, _1) }
      next :failed_checks unless response.fetch("status") == "ok"

      conversation.turns.create!(position: position, speaker: "learner", text: text)
      conversation.turns.create!(position: position + 1, speaker: "character", text: response.fetch("reply"),
                                 evaluation_trace: traces.last)
      conversation.update!(goals: Conversation.merge_goals(conversation.goals, response.fetch("goals")))
      # The agent only sees this turn's check, so a goal it took back can leave it open while every goal is met here.
      finish(conversation) if response.fetch("closed") || conversation.all_goals_met?
      :ok
    end
  end

  # The agent holds no state: the frozen scenario version and the whole transcript, with the new message last.
  def self.payload(conversation, text)
    content = conversation.scenario.content
    turns = conversation.turns.map { { speaker: _1.speaker, text: _1.text } }
    { scenario: content.fetch("scenario"), interlocutor: content.fetch("interlocutor"),
      turns: turns + [ { speaker: "learner", text: text } ] }
  end

  def self.finish(conversation)
    conversation.finish!(conversation.all_goals_met? ? "goals_met" : "turn_limit")
  end

  def self.create_trace(conversation, trace)
    conversation.participant.evaluation_traces.create!(
      trace.slice(*EvaluationTrace::AGENT_FIELDS).merge("conversation" => conversation)
    )
  end
end
