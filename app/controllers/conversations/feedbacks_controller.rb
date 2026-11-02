module Conversations
  class FeedbacksController < ApplicationController
    before_action :require_eligible_consent!

    def show
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :not_found unless conversation.feedback

      render json: FeedbackSerializer.new(conversation.feedback)
    end
  end
end
