# Holds learner text, so it belongs to the participant and is deleted with them.
class EvaluationTrace < ApplicationRecord
  STATUSES = %w[ok failed_checks error].freeze

  belongs_to :participant
  belongs_to :placement_attempt, class_name: "Placement::Attempt", optional: true

  validates :step, presence: true
  validates :status, inclusion: { in: STATUSES }

  # Rule-based steps run no model, so only a model call must name its prompt.
  with_options if: :model? do
    validates :prompt_path, presence: true
    validates :prompt_sha256, format: { with: /\A\h{64}\z/ }
  end
end
