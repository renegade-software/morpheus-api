class StageQuizzesController < ApplicationController
  before_action :require_eligible_consent!
  before_action :require_quiz!

  # GET /stage_quizzes/:stage
  def show
    render json: {
      stage: stage,
      pass_mark: StageQuiz::PASS_MARK,
      passed: current_participant.stage_quiz_attempts.passed.exists?(stage: stage),
      questions: StageQuiz.public_questions(stage)
    }
  end

  # POST /stage_quizzes/:stage/attempt  { choices: [0, 2, 1, 0] }
  def attempt
    attempt = StageQuizAttempt.record!(current_participant, stage, choices)
    render json: { stage: stage, correct: attempt.correct, total: attempt.items.size,
                   passed: attempt.passed, pass_mark: StageQuiz::PASS_MARK, results: attempt.results }
  end

  private

  def stage
    params.expect(:stage)
  end

  def choices
    Array(params[:choices]).map { Integer(_1, exception: false) }
  end

  def require_quiz!
    head :not_found unless StageQuiz.questions(stage)
  end
end
