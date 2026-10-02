module Placement
  # The order of the test: reading A → B → C (stopping at the first text with a wrong answer), listening A → B → C for
  # everyone, then writing and speaking. Also works out the reading and listening results as each section ends.
  module Steps
    FIRST = "reading.a".freeze
    TIERS = %w[a b c].freeze
    LISTENING_PLAYS = 2
    LISTENING_ANSWER_SECONDS = 30

    def self.item_keys(step)
      section, tier = step.split(".")
      case section
      when "reading" then [ "reading.#{tier}.q1", "reading.#{tier}.q2" ]
      when "listening" then [ "listening.#{tier}" ]
      else []
      end
    end

    # Called after the current step's responses are saved; moves the attempt on and records section results.
    def self.advance!(attempt)
      section, tier = attempt.current_step.split(".")

      case section
      when "reading" then advance_reading(attempt, tier)
      when "listening" then advance_listening(attempt, tier)
      end
    end

    def self.advance_reading(attempt, tier)
      passed = attempt.placement_responses.where(section: "reading", item_key: item_keys("reading.#{tier}")).all?(&:correct)

      if passed && tier != TIERS.last
        attempt.current_step = "reading.#{next_tier(tier)}"
      else
        attempt.reading_result = reading_result(attempt)
        attempt.current_step = "listening.#{TIERS.first}"
      end
    end

    def self.advance_listening(attempt, tier)
      if tier == TIERS.last
        attempt.listening_result = listening_result(attempt)
        attempt.current_step = "writing"
      else
        attempt.current_step = "listening.#{next_tier(tier)}"
      end
    end

    # Texts passed in a row: 0 means the A text was failed, 3 means all three were passed.
    def self.reading_result(attempt)
      TIERS.take_while { |tier|
        responses = attempt.placement_responses.where(section: "reading", item_key: item_keys("reading.#{tier}"))
        responses.size == 2 && responses.all?(&:correct)
      }.size
    end

    # The hardest clip answered correctly: 0 for none, 1 for A, 2 for B, 3 for C.
    def self.listening_result(attempt)
      correct_tiers = attempt.placement_responses.where(section: "listening", correct: true).map { _1.item_key.split(".").last }
      correct_tiers.map { TIERS.index(_1) + 1 }.max || 0
    end

    def self.next_tier(tier)
      TIERS.fetch(TIERS.index(tier) + 1)
    end

    private_class_method :advance_reading, :advance_listening, :next_tier
  end
end
