module Placement
  # The only way placement content reaches the browser. Every field is picked by hand, so answer keys, notes,
  # anchors, scoring rules and listening transcripts can't leak through.
  class StepPresenter
    def initialize(attempt)
      @attempt = attempt
    end

    def as_json(*)
      { status: @attempt.status, current_step: @attempt.current_step, step: step }
    end

    private

    def step
      return if @attempt.current_step.nil?

      section, tier = @attempt.current_step.split(".")
      case section
      when "reading" then reading(tier)
      when "listening" then listening(tier)
      when "writing" then writing
      when "speaking" then speaking
      end
    end

    def reading(tier)
      text = Content.reading.fetch(tier)
      {
        section: "reading",
        tier: tier,
        seconds: text["seconds"],
        text: text["text"],
        questions: text["questions"].each_with_index.map { |question, index|
          question(key: "reading.#{tier}.q#{index + 1}", question: question)
        }
      }
    end

    def listening(tier)
      clip = Content.listening.fetch(tier)
      {
        section: "listening",
        tier: tier,
        audio_url: clip["audio"],
        plays: Steps::LISTENING_PLAYS,
        answer_seconds: Steps::LISTENING_ANSWER_SECONDS,
        question: question(key: "listening.#{tier}", question: clip["question"])
      }
    end

    def writing
      task = Content.writing["task"]
      { section: "writing", seconds: task["seconds"], situation: task["situation"], bullets: task["bullets"].map { _1["text"] } }
    end

    def speaking
      prompt = Content.speaking_prompt_for(@attempt.reading_result)
      { section: "speaking", seconds: Content.speaking["seconds"], prompt: prompt["text"], follow_up: Content.speaking["follow_up"] }
    end

    def question(key:, question:)
      { key: key, prompt: question["prompt"], options: question["options"] }
    end
  end
end
