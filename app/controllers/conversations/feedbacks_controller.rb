module Conversations
  class FeedbacksController < ApplicationController
    before_action :require_eligible_consent!

    # The review screen polls this until the status is ready or failed. 404: the conversation got no feedback
    # (still active, abandoned, or ended before the learner wrote anything).
    def show
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :not_found unless conversation.feedback

      render json: FeedbackSerializer.new(conversation.feedback)
    end
  end
end
