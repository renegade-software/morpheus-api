class GenerateFeedbackJob < ApplicationJob
  queue_as :scoring
  retry_on Agent::Unavailable, wait: :polynomially_longer, attempts: 5 do |job, _error|
    job.arguments.first.update!(status: "failed")
  end
  discard_on Agent::Rejected do |job, _error|
    job.arguments.first.update!(status: "failed")
  end
  discard_on ActiveJob::DeserializationError

  def perform(feedback)
    return unless feedback.pending?

    conversation = feedback.conversation
    turns = conversation.turns.to_a
    response = Agent.feedback(payload(feedback, conversation, turns))

    Feedback.transaction do
      traces = response.fetch("traces").map { create_trace(conversation, _1) }
      if response.fetch("status") == "ok"
        store(feedback, response, turns, traces.last)
      else
        feedback.update!(status: "failed", evaluation_trace: traces.last)
      end
    end
  end

  private

  def payload(feedback, conversation, turns)
    { scenario: conversation.scenario.content.fetch("scenario").merge("mode" => feedback.mode), mode: feedback.mode,
      # A voice turn's words carry Scribe's confidence in each one, which feedback uses to judge intelligibility.
      turns: turns.map { { speaker: _1.speaker, text: _1.text, words: _1.words }.compact },
      goals: conversation.goals, display_language: feedback.display_language }
  end

  def store(feedback, response, turns, trace)
    response.fetch("comments").each do |comment|
      feedback.comments.create!(
        turn: turns.fetch(comment.fetch("turn")), quote: comment.fetch("quote"),
        start_offset: comment.fetch("start"), end_offset: comment.fetch("end"),
        **comment.slice("skill", "category", "priority", "explanation", "rewrite").symbolize_keys
      )
    end
    response.fetch("scores").each { feedback.scores.create!(_1.slice("skill", "score", "reason")) }
    feedback.update!(status: "ready", summary: response.fetch("summary"), dropped: response.fetch("dropped"),
                     evaluation_trace: trace)
  end

  def create_trace(conversation, trace)
    conversation.participant.evaluation_traces.create!(
      trace.slice(*EvaluationTrace::AGENT_FIELDS).merge("conversation" => conversation)
    )
  end
end
