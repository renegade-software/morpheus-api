module Placement::Steps
  # The order of the test: reading A → B → C (stopping at the first text with a wrong answer), listening A → B → C for
  # everyone, then writing and speaking. Also works out the reading and listening results as each section ends.
  FIRST = "reading.a".freeze
  TIERS = PlacementPassage::TIERS

  def self.passage(attempt, step = attempt.current_step)
    section, tier = step.split(".")
    attempt.placement_form.placement_passages.find_by!(section: section, tier: tier)
  end

  # The questions the current step must answer: both questions of a reading text, or the one listening question.
  def self.questions(attempt)
    section = attempt.current_step.split(".").first
    return PlacementQuestion.none unless PlacementPassage::SECTIONS.include?(section)

    passage(attempt).placement_questions
  end

  # The current step's questions with no response yet, in order. Answers are saved one at a time, so after a refresh
  # this is where the learner picks up.
  def self.unanswered_questions(attempt)
    questions(attempt).where.not(id: attempt.placement_responses.select(:placement_question_id))
  end

  def self.writing_task(attempt)
    PlacementWritingTask.find_by!(placement_form: attempt.placement_form)
  end

  def self.speaking_task(attempt)
    attempt.placement_form.placement_speaking_tasks.for_reading_result(attempt.reading_result)
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
    if passed?(attempt, passage(attempt)) && tier != TIERS.last
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
    TIERS.take_while { |tier| passed?(attempt, passage(attempt, "reading.#{tier}")) }.size
  end

  # The hardest clip answered correctly: 0 for none, 1 for A, 2 for B, 3 for C.
  def self.listening_result(attempt)
    correct_tiers = attempt.placement_responses
      .joins(placement_question: :placement_passage)
      .where(correct: true, placement_passages: { section: "listening" })
      .pluck("placement_passages.tier")
    correct_tiers.map { TIERS.index(_1) + 1 }.max || 0
  end

  def self.passed?(attempt, passage)
    responses = attempt.placement_responses.where(placement_question: passage.placement_questions)
    responses.size == passage.placement_questions.size && responses.all?(&:correct)
  end

  def self.next_tier(tier)
    TIERS.fetch(TIERS.index(tier) + 1)
  end

  private_class_method :advance_reading, :advance_listening, :passed?, :next_tier
end
