module Conversations
  class VoiceTurnsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active?
      return head :forbidden unless current_participant.current_consent&.voice_allowed?
      return head :unprocessable_content unless conversation.scenario.mode == "voice" && valid_audio?

      case Conversation::TakeVoiceTurn.call(conversation, params[:audio])
      when :ok then render json: ConversationSerializer.new(conversation.reload), status: :created
      when :no_speech then render json: { error: "no_speech" }, status: :unprocessable_content
      else render json: { error: "failed_checks" }, status: :bad_gateway
      end
    rescue Agent::Unavailable
      render json: { error: "agent_unavailable" }, status: :service_unavailable
    rescue ActiveRecord::RecordNotUnique
      head :conflict
    end

    private

    def valid_audio?
      audio = params[:audio]
      audio.respond_to?(:content_type) && audio.content_type.to_s.start_with?("audio/") &&
        audio.size.between?(1, Conversation::TakeVoiceTurn::MAX_BYTES)
    end
  end
end
