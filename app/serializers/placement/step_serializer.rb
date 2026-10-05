module Placement
  # The only way placement content reaches the browser. Every field is picked by hand (an allow list), so answer keys,
  # transcripts, anchors, rubric text and scoring rules stay on the server even when new columns are added.
  class StepSerializer
    include Rails.application.routes.url_helpers

    def initialize(attempt)
      @attempt = attempt
    end

    def as_json(*)
      { status: @attempt.status, current_step: @attempt.current_step, step: step }
    end

    private

    def step
      return if @attempt.current_step.nil?

      case @attempt.current_step.split(".").first
      when "reading" then reading
      when "listening" then listening
      when "writing" then writing
      when "speaking" then speaking
      end
    end

    def reading
      passage = Steps.passage(@attempt)
      {
        section: "reading",
        tier: passage.tier,
        seconds: passage.seconds,
        seconds_left: seconds_left(passage.seconds),
        text: passage.body,
        questions: passage.placement_questions.map { question(_1) }
      }
    end

    # Worked out here from when the learner pressed Empezar, so neither a refresh nor the device's clock changes it.
    # nil until the step has started; 0 once its time is up.
    def seconds_left(seconds)
      return if @attempt.step_started_at.nil?

      [ seconds - (Time.current - @attempt.step_started_at), 0 ].max.round(1)
    end

    # The audio path is relative to the API; Active Storage redirects it to the file. The clip's clock is its plays
    # times its length plus the answer time; only the browser knows the length (from the file), so the server sends how
    # long ago the first play was and the browser works out what's left.
    def listening
      passage = Steps.passage(@attempt)
      {
        section: "listening",
        tier: passage.tier,
        audio_path: rails_blob_path(passage.audio, only_path: true),
        plays: passage.plays,
        plays_left: passage.plays - @attempt.plays_used,
        answer_seconds: passage.seconds,
        elapsed_seconds: elapsed_seconds,
        question: question(passage.placement_questions.first)
      }
    end

    # Seconds since the step started (the first play, or Empezar); nil before that.
    def elapsed_seconds
      return if @attempt.step_started_at.nil?

      (Time.current - @attempt.step_started_at).round(1)
    end

    def writing
      task = Steps.writing_task(@attempt)
      {
        section: "writing",
        seconds: task.seconds,
        seconds_left: seconds_left(task.seconds),
        situation: task.prompt,
        bullets: task.bullets.map { _1["text"] }
      }
    end

    def speaking
      task = Steps.speaking_task(@attempt)
      {
        section: "speaking",
        prep_seconds: task.prep_seconds,
        seconds: task.seconds,
        retakes_left: task.retakes - @attempt.retakes_used,
        prompt: task.prompt,
        elapsed_seconds: elapsed_seconds
      }
    end

    # `answered` says whether the learner already answered it (never what they chose or whether it was right), so the
    # browser can resume at the next unanswered question.
    def question(question)
      { id: question.id, prompt: question.prompt, options: question.options, answered: answered_ids.include?(question.id) }
    end

    def answered_ids
      @answered_ids ||= @attempt.placement_responses.pluck(:placement_question_id).to_set
    end
  end
end
