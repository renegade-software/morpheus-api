# Holds learner text, so it belongs to the participant and is deleted with them.
class EvaluationTrace < ApplicationRecord
  STATUSES = %w[ok failed_checks error].freeze
  # The fields of the agent's TraceStep that are columns here, one to one.
  AGENT_FIELDS = %w[step prompt_path prompt_sha256 model effort input output input_tokens output_tokens latency_ms
                    cost_usd status error retried].freeze

  belongs_to :participant
  belongs_to :placement_attempt, class_name: "Placement::Attempt", optional: true

  validates :step, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Speech-to-text runs a model but has no prompt to name.
  TRANSCRIPTION_STEPS = %w[transcribe_placement_speaking].freeze

  # Rule-based steps run no model, so only a prompted model call must name its prompt.
  with_options if: :prompted_model_call? do
    validates :prompt_path, presence: true
    validates :prompt_sha256, format: { with: /\A\h{64}\z/ }
  end

  def prompted_model_call?
    model? && !TRANSCRIPTION_STEPS.include?(step)
  end
end
