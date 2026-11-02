module Placement
  class ScoreSpeakingJob < ApplicationJob
    MISSING_STEP = "rate_missing_placement_speaking".freeze

    queue_as :scoring
    retry_on Agent::Unavailable, wait: :polynomially_longer, attempts: 5
    discard_on ActiveJob::DeserializationError

    def perform(recording)
      unless recording.rated?
        if recording.audio.attached?
          store(recording, Agent.score_speaking(Placement::SpeakingPayload.build(recording)))
        else
          rate_missing(recording)
        end
      end
      Placement::Scoring.complete_if_ready(recording.attempt)
    end

    private

    def store(recording, response)
      Recording.transaction do
        traces = response.fetch("traces").map { |trace| create_trace(recording, trace.slice(*EvaluationTrace::AGENT_FIELDS)) }
        recording.update!(response.slice("transcript", "word_timings", "speaking_ms", "word_count", "long_pauses"))
        if response.fetch("status") == "ok"
          rate(recording, response.fetch("rating"), traces.last)
        else
          recording.attempt.update!(status: "failed")
        end
      end
    end

    def rate(recording, rating, trace)
      recording.update!(
        range_level: rating.fetch("range"),
        accuracy_level: rating.fetch("accuracy"),
        fluency_level: rating.fetch("fluency"),
        coherence_level: rating.fetch("coherence"),
        overall_level: rating.fetch("overall"),
        evidence: rating.fetch("evidence"),
        evaluation_trace: trace
      )
    end

    def rate_missing(recording)
      Recording.transaction do
        trace = create_trace(recording, "step" => MISSING_STEP, "status" => "ok",
                                        "input" => { "timed_out" => recording.timed_out, "audio" => false },
                                        "output" => { "overall" => 0 })
        recording.update!(**Recording::LEVEL_COLUMNS.index_with(0), evidence: {}, evaluation_trace: trace)
      end
    end

    def create_trace(recording, fields)
      recording.attempt.participant.evaluation_traces.create!(fields.merge("placement_attempt" => recording.attempt))
    end
  end
end
