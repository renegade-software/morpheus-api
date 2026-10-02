# Holds learner text, so it belongs to the participant and is deleted with them.
class EvaluationTrace < ApplicationRecord
  STATUSES = %w[ok failed_checks error].freeze

  belongs_to :participant

  validates :step, :model, :prompt_path, presence: true
  validates :prompt_sha256, format: { with: /\A\h{64}\z/ }
  validates :status, inclusion: { in: STATUSES }
end
