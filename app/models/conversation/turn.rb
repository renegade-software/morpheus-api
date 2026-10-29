class Conversation::Turn < ApplicationRecord
  SPEAKERS = %w[learner character].freeze

  belongs_to :conversation
  # The call that wrote a character turn; nil for the learner's turns and the opening.
  belongs_to :evaluation_trace, optional: true
  # A voice turn's note: the learner's recording, or the character's reply in its pinned voice. Private bucket;
  # destroying the turn purges the file, so it goes with the participant.
  has_one_attached :audio

  validates :speaker, inclusion: { in: SPEAKERS }
  validates :text, presence: true
  validates :position, uniqueness: { scope: :conversation_id }
end
