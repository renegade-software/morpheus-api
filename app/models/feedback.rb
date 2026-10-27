# A finished conversation's feedback (FR7–FR9): written once by the agent, then read on the review screen. Holds the
# learner's words in its quotes and summary, so it goes with the conversation when the participant is deleted.
class Feedback < ApplicationRecord
  STATUSES = %w[pending ready failed].freeze

  belongs_to :conversation
  # The call whose answer was stored; nil while pending.
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
