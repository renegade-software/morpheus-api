class Conversation::Turn < ApplicationRecord
  SPEAKERS = %w[learner character].freeze

  belongs_to :conversation
  # The call that wrote a character turn; nil for the learner's turns and the opening.
  belongs_to :evaluation_trace, optional: true

  validates :speaker, inclusion: { in: SPEAKERS }
  validates :text, presence: true
  validates :position, uniqueness: { scope: :conversation_id }
end
