class Conversation::Turn < ApplicationRecord
  SPEAKERS = %w[learner character].freeze

  belongs_to :conversation
  belongs_to :evaluation_trace, optional: true
  has_one_attached :audio

  validates :speaker, inclusion: { in: SPEAKERS }
  validates :text, presence: true
  validates :position, uniqueness: { scope: :conversation_id }
end
