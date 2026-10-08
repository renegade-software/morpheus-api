module Placement
  # Transcribes and rates a placement recording through morpheus-agent, and stores the transcript, the fluency
  # numbers and a trace for every step. Queued once the audio is in storage (see RecordingsController).
  class ScoreSpeakingJob < ApplicationJob
    MISSING_STEP = "rate_missing_placement_speaking".freeze

    queue_as :scoring
    retry_on Placement::Agent::Unavailable, wait: :polynomially_longer, attempts: 5
    # The learner deleted their data before the job ran.
    discard_on ActiveJob::DeserializationError

    def perform(recording)
      return if recording.rated? # a rerun after a success
      return rate_missing(recording) unless recording.audio.attached?

      store(recording, Placement::Agent.score_speaking(Placement::SpeakingPayload.build(recording)))
    end

    private

    def store(recording, response)
      Recording.transaction do
        traces = response.fetch("traces").map { |trace| create_trace(recording, trace.slice(*EvaluationTrace::AGENT_FIELDS)) }
        # Kept even when the rating fails its checks: the transcript is what a reviewer reads first.
        recording.update!(response.slice("transcript", "word_timings", "speaking_ms", "word_count", "long_pauses"))
        if response.fetch("status") == "ok"
          rate(recording, response.fetch("rating"), traces.last)
        else
          recording.attempt.update!(status: "failed") # results page: "Revisaremos tus respuestas"
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

    # Time ran out before anything was recorded: nothing to transcribe, so A1 by rule, still traced with no model.
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
