module Conversations
  class VoiceRepliesController < ApplicationController
    before_action :require_eligible_consent!

    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active? && conversation.turns.last.speaker == "learner"
      return head :unprocessable_content unless conversation.voice?

      case Conversation::VoiceReply.call(conversation)
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
