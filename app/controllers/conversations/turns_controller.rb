module Conversations
  class TurnsController < ApplicationController
    before_action :require_eligible_consent!

    # Sends the learner's message and answers with the character's reply, while the learner waits.
    # 503: the agent is busy or down; 502: it answered but failed its checks twice. Either way nothing was saved, so
    # the learner can send the same message again.
    def create
      conversation = current_participant.conversations.find(params.expect(:conversation_id))
      return head :conflict unless conversation.active?
      # A scenario is practised one way only (2026-10-29): typed messages here, voice notes in VoiceTurnsController.
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
      head :conflict # a second send raced the first one to the same position
    end
  end
end
