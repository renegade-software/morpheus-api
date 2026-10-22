# What the conversation screen needs, picked by hand like the placement serializer: the transcript, the goal checks
# and where the turn limit stands. The scenario's agenda and the character's instructions stay on the server.
class ConversationSerializer
  def initialize(conversation)
    @conversation = conversation
  end

  def as_json(*)
    scenario = @conversation.scenario
    {
      id: @conversation.id,
      scenario: scenario.key,
      status: @conversation.status,
      finished_reason: @conversation.finished_reason,
      turn_limit: scenario.turn_limit,
      extra_turns: scenario.extra_turns,
      turns: @conversation.turns.map { { speaker: _1.speaker, text: _1.text, sent_at: _1.created_at } },
      goals: @conversation.goals
    }
  end
end
