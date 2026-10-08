module Placement::Steps
  # The order of the test: reading A → B → C (stopping at the first text with a wrong answer), listening A → B → C for
  # everyone, then writing and speaking. Also works out the reading and listening results as each section ends.
  FIRST = "reading.a".freeze
  TIERS = Placement::Passage::TIERS

  def self.passage(attempt, step = attempt.current_step)
    section, tier = step.split(".")
    attempt.form.passages.find_by!(section: section, tier: tier)
  end

  # The questions the current step must answer: both questions of a reading text, or the one listening question.
  def self.questions(attempt)
    section = attempt.current_step.split(".").first
    return Placement::Question.none unless Placement::Passage::SECTIONS.include?(section)

    passage(attempt).questions
  end

  def self.unanswered_questions(attempt)
    questions(attempt).where.not(id: attempt.responses.select(:placement_question_id))
  end

  def self.writing_task(attempt)
    Placement::WritingTask.find_by!(form: attempt.form)
  end

  def self.speaking_task(attempt)
    attempt.form.speaking_tasks.for_reading_result(attempt.reading_result)
  end

  def self.advance!(attempt)
    section, tier = attempt.current_step.split(".")

    case section
    when "reading" then advance_reading(attempt, tier)
    when "listening" then advance_listening(attempt, tier)
    when "writing" then advance_writing(attempt)
    when "speaking" then finish(attempt)
    end
    attempt.step_started_at = nil
    attempt.plays_used = 0
  end

  def self.advance_writing(attempt)
    if voice_allowed?(attempt)
      attempt.current_step = "speaking"
    else
      finish(attempt)
    end
  end

  def self.voice_allowed?(attempt)
    attempt.participant.current_consent&.voice_allowed? || false
  end

  def self.finish(attempt)
    attempt.current_step = nil
    attempt.status = "scoring"
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
    correct_tiers = attempt.responses
      .joins(question: :passage)
      .where(correct: true, placement_passages: { section: "listening" })
      .pluck("placement_passages.tier")
    correct_tiers.map { TIERS.index(_1) + 1 }.max || 0
  end

  def self.passed?(attempt, passage)
    responses = attempt.responses.where(question: passage.questions)
    responses.size == passage.questions.size && responses.all?(&:correct)
  end

  def self.next_tier(tier)
    TIERS.fetch(TIERS.index(tier) + 1)
  end

  # voice_allowed? stays public: Scoring needs the same rule to know whether speaking is part of the range.
  private_class_method :advance_reading, :advance_listening, :advance_writing, :finish, :passed?, :next_tier
end
