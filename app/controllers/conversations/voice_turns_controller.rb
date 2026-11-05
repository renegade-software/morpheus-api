module Conversations
  class VoiceTurnsController < ApplicationController
    before_action :require_eligible_consent!

    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active? && conversation.turns.last.speaker == "character"
      return head :forbidden unless current_participant.current_consent&.voice_allowed?
      return head :unprocessable_content unless conversation.voice? && valid_audio?

      case Conversation::TakeVoiceTurn.call(conversation, params[:audio])
      when :ok then render json: ConversationSerializer.new(conversation.reload), status: :created
      when :no_speech then render json: { error: "no_speech" }, status: :unprocessable_content
      end
    rescue Agent::Unavailable, Agent::Rejected
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
