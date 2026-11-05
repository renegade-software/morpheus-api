# A stage's grammar quiz, read from content/stage_quizzes.yaml. C2 stages have none.
module StageQuiz
  FILE = Rails.root.join("content", "stage_quizzes.yaml")
  PASS_MARK = 3

  def self.questions(stage)
    all.fetch(stage, nil)
  end

  def self.stages
    all.keys
  end

  # Without the answers, for the learner.
  def self.public_questions(stage)
    questions(stage).map { _1.slice("id", "prompt", "options") }
  end

  # choices: one option index per question, in order. Unanswered questions count as wrong.
  def self.grade(stage, choices)
    questions(stage).each_with_index.map do |question, index|
      choice = choices[index]
      question.merge("choice" => choice, "correct" => choice == question.fetch("answer"))
    end
  end

  def self.all
    @all = nil if Rails.env.development?
    @all ||= YAML.load_file(FILE).freeze
  end
  private_class_method :all
end
