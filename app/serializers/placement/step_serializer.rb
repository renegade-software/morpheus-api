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
        text: passage.body,
        questions: passage.placement_questions.map { question(_1) }
      }
    end

    # The audio path is relative to the API; Active Storage redirects it to the file.
    def listening
      passage = Steps.passage(@attempt)
      {
        section: "listening",
        tier: passage.tier,
        audio_path: rails_blob_path(passage.audio, only_path: true),
        plays: Steps::LISTENING_PLAYS,
        answer_seconds: Steps::LISTENING_ANSWER_SECONDS,
        question: question(passage.placement_questions.first)
      }
    end

    def writing
      task = Steps.writing_task(@attempt)
      { section: "writing", seconds: task.seconds, situation: task.prompt, bullets: task.bullets.map { _1["text"] } }
    end

    def speaking
      task = Steps.speaking_task(@attempt)
      { section: "speaking", seconds: task.seconds, prompt: task.prompt, follow_up: task.follow_up }
    end

    def question(question)
      { id: question.id, prompt: question.prompt, options: question.options }
    end
  end
end
