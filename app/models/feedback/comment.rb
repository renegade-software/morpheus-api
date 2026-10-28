# One comment pinned to the learner's words (FR7). The offsets slice the turn's stored text, which is what the
# review screen shows; the quote is Claude's copy, kept for the grounding analysis.
class Feedback::Comment < ApplicationRecord
  PRIORITIES = %w[essential recommended additional].freeze
  FLAGS = %w[wrong unhelpful].freeze # FR11

  belongs_to :feedback
  belongs_to :turn, class_name: "Conversation::Turn", foreign_key: :conversation_turn_id

  validates :quote, :skill, :category, :explanation, :rewrite, presence: true
  validates :priority, inclusion: { in: PRIORITIES }
  validates :flagged_as, inclusion: { in: FLAGS }, allow_nil: true
  validates :end_offset, comparison: { greater_than: :start_offset }
end
