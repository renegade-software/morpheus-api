class PlacementForm < ApplicationRecord
  STATUSES = %w[draft active retired].freeze

  has_many :placement_passages, dependent: :destroy
  has_many :placement_questions, through: :placement_passages
  has_one :placement_writing_task, dependent: :destroy
  has_many :placement_writing_anchors, through: :placement_writing_task
  has_many :placement_speaking_tasks, -> { order(:tier) }, dependent: :destroy
  has_many :placement_speaking_anchors, through: :placement_speaking_tasks
  has_many :placement_rubric_descriptors, dependent: :destroy
  has_many :placement_attempts, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :status, inclusion: { in: STATUSES }

  def self.current
    find_by(status: "active")
  end

  def locked?
    status != "draft"
  end

  # Learners only ever see one form. Activating a new one retires the old; attempts already on it keep pointing at it.
  def activate!
    missing_audio = placement_passages.where(section: "listening").reject { _1.audio.attached? }
    if missing_audio.any?
      raise ArgumentError, "listening audio missing for tiers #{missing_audio.map(&:tier).join(', ')}"
    end

    transaction do
      PlacementForm.where(status: "active").update_all(status: "retired", updated_at: Time.current)
      update!(status: "active")
    end
  end
end
