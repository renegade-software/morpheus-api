# What the review screen needs, picked by hand like the conversation serializer. No quotes and no dropped comments:
# the screen slices each turn's stored text with the offsets, so it can never show words Claude made up.
class FeedbackSerializer
  def initialize(feedback)
    @feedback = feedback
  end

  def as_json(*)
    return { status: @feedback.status } unless @feedback.status == "ready"

    {
      status: @feedback.status,
      summary: @feedback.summary,
      comments: @feedback.comments.includes(:turn).order(:id).map { comment(_1) },
      scores: @feedback.scores.order(:id).map { { skill: _1.skill, score: _1.score, reason: _1.reason } }
    }
  end

  private

  # `turn` is the position, the same index the conversation serializer's turns use.
  def comment(comment)
    { id: comment.id, turn: comment.turn.position, start: comment.start_offset, end: comment.end_offset,
      skill: comment.skill, category: comment.category, priority: comment.priority,
      explanation: comment.explanation, rewrite: comment.rewrite, flagged_as: comment.flagged_as }
  end
end
