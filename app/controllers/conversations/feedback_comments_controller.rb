module Conversations
  class FeedbackCommentsController < ApplicationController
    before_action :require_eligible_consent!

    # FR11: the learner flags a comment as wrong or unhelpful from the review screen. 404: not this learner's comment.
    def update
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      comment = conversation.feedback&.comments&.find_by(id: params.expect(:id))
      return head :not_found unless comment
      return head :unprocessable_content unless comment.update(flagged_as: params.expect(:flagged_as))

      render json: { id: comment.id, flagged_as: comment.flagged_as }
    end
  end
end
