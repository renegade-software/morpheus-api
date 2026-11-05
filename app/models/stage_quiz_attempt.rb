class StageQuizAttempt < ApplicationRecord
  belongs_to :participant

  validates :stage, inclusion: { in: -> { StageQuiz.stages } }
  validates :items, presence: true

  scope :passed, -> { where(passed: true) }

  def self.record!(participant, stage, choices)
    items = StageQuiz.grade(stage, choices)
    correct = items.count { _1.fetch("correct") }
    participant.stage_quiz_attempts.create!(stage: stage, items: items, correct: correct,
                                            passed: correct >= StageQuiz::PASS_MARK)
  end

  def results
    items.map { _1.slice("id", "prompt", "options", "answer", "choice", "correct", "point") }
  end
end
