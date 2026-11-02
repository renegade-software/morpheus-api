class Feedback < ApplicationRecord
  STATUSES = %w[pending ready failed].freeze

  belongs_to :conversation
  belongs_to :evaluation_trace, optional: true
  has_many :comments, dependent: :destroy
  has_many :scores, dependent: :destroy

  validates :status, inclusion: { in: STATUSES }
  validates :mode, inclusion: { in: Scenario::MODES }
  validates :display_language, inclusion: { in: Participant::DISPLAY_LANGUAGES }

  def pending?
    status == "pending"
  end
end
