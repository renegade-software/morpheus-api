module Conversations
  class TurnsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active?
      return head :unprocessable_content unless conversation.scenario.mode == "text"

      text = params.expect(:text).to_s.strip
      return head :unprocessable_content if text.empty? || text.length > Conversation::TakeTurn::MAX_TEXT

      case Conversation::TakeTurn.call(conversation, text)
      when :ok then render json: ConversationSerializer.new(conversation.reload), status: :created
      else render json: { error: "failed_checks" }, status: :bad_gateway
      end
    rescue Agent::Unavailable
      render json: { error: "agent_unavailable" }, status: :service_unavailable
    rescue ActiveRecord::RecordNotUnique
      head :conflict
    end
  end
end
