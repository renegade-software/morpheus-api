module Conversations
  class TurnsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active?
      return head :unprocessable_content unless %w[text writing].include?(conversation.scenario.mode)

      text = params.expect(:text).to_s.strip
      return head :unprocessable_content if text.empty? || text.length > Conversation::TakeTurn.max_length(conversation)

      case Conversation::TakeTurn.call(conversation, text)
      when :ok then render json: ConversationSerializer.new(conversation.reload), status: :created
      else render json: { error: "failed_checks" }, status: :bad_gateway
      end
    rescue Agent::Unavailable, Agent::Rejected
      render json: { error: "agent_unavailable" }, status: :service_unavailable
    rescue ActiveRecord::RecordNotUnique
      head :conflict
    end
  end
end
