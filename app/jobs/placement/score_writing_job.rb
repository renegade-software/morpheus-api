module Placement
  # Rates a placement message through morpheus-agent and stores a trace for every call. Queued as soon as the message
  # is sent, so the rating is usually done before the learner finishes the speaking part.
  class ScoreWritingJob < ApplicationJob
    EMPTY_STEP = "rate_empty_placement_writing".freeze

    queue_as :scoring
    retry_on Placement::Agent::Unavailable, wait: :polynomially_longer, attempts: 5
    # The learner deleted their data before the job ran.
    discard_on ActiveJob::DeserializationError

    def perform(writing)
      return if writing.rated? # a rerun after a success
      return rate_empty(writing) if writing.text.blank?

      store(writing, Placement::Agent.score_writing(Placement::WritingPayload.build(writing)))
    end

    private

    def store(writing, response)
      Writing.transaction do
        traces = response.fetch("traces").map { |trace| create_trace(writing, trace.slice(*EvaluationTrace::AGENT_FIELDS)) }
        if response.fetch("status") == "ok"
          rate(writing, response.fetch("rating"), traces.last)
        else
          writing.attempt.update!(status: "failed") # results page: "Revisaremos tus respuestas"
        end
      end
    end

    def rate(writing, rating, trace)
      writing.update!(
        production_level: rating.fetch("production"),
        range_level: rating.fetch("range"),
        accuracy_level: rating.fetch("accuracy"),
        coherence_level: rating.fetch("coherence"),
        overall_level: rating.fetch("overall"),
        evidence: rating.fetch("evidence"),
        evaluation_trace: trace
      )
    end

    # No words, nothing for Claude to rate: A1 by rule. Still traced, with no model, so every rating has a record.
    def rate_empty(writing)
      Writing.transaction do
        trace = create_trace(writing, "step" => EMPTY_STEP, "status" => "ok",
                                      "input" => { "text" => writing.text, "timed_out" => writing.timed_out },
                                      "output" => { "overall" => 0 })
        writing.update!(**Writing::LEVEL_COLUMNS.index_with(0), evidence: {}, evaluation_trace: trace)
      end
    end

    def create_trace(writing, fields)
      writing.attempt.participant.evaluation_traces.create!(fields.merge("placement_attempt" => writing.attempt))
    end
  end
end
