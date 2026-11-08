module Placement
  class Form < ApplicationRecord
    STATUSES = %w[draft active retired].freeze
    # intake places every new learner; final is the optional test at the end, on a different form (form B).
    PURPOSES = %w[intake final].freeze

    has_many :passages, foreign_key: :placement_form_id, dependent: :destroy
    has_many :questions, through: :passages
    has_one :writing_task, foreign_key: :placement_form_id, dependent: :destroy
    has_many :writing_anchors, through: :writing_task
    has_many :speaking_tasks, -> { order(:tier) }, foreign_key: :placement_form_id, dependent: :destroy
    has_many :speaking_anchors, through: :speaking_tasks
    has_many :rubric_descriptors, foreign_key: :placement_form_id, dependent: :destroy
    has_many :attempts, foreign_key: :placement_form_id, dependent: :restrict_with_exception

    validates :name, presence: true, uniqueness: true
    validates :status, inclusion: { in: STATUSES }
    validates :purpose, inclusion: { in: PURPOSES }

    def self.current(purpose = "intake")
      find_by(status: "active", purpose: purpose)
    end

    def locked?
      status != "draft"
    end

    def activate!
      missing_audio = passages.where(section: "listening").reject { _1.audio.attached? }
      if missing_audio.any?
        raise ArgumentError, "listening audio missing for tiers #{missing_audio.map(&:tier).join(', ')}"
      end

      transaction do
        Form.where(status: "active", purpose: purpose).update_all(status: "retired", updated_at: Time.current)
        update!(status: "active")
      end
    end
  end
end
