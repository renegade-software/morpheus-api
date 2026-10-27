class ConversationsController < ApplicationController
  before_action :require_eligible_consent!

  # Starts a conversation on the scenario's current version, with the character's opening as the first turn.
  def create
    scenario = Scenario.current(params.expect(:scenario))
    return head :not_found unless scenario

    Conversation.abandon_idle!(current_participant)

    render json: ConversationSerializer.new(Conversation.start!(current_participant, scenario)), status: :created
  end

  def show
    render json: ConversationSerializer.new(conversation)
  end

  # Terminar, or the chat screen's idle limit: the learner ends it, or leaves, before the goals or the turns run out.
  def finish
    return head :conflict unless conversation.active?

    conversation.finish!(params[:reason] == "abandoned" ? "abandoned" : "ended_by_learner")
    render json: ConversationSerializer.new(conversation)
  end

  private

  def conversation
    @conversation ||= current_participant.conversations.find(params.expect(:id))
  end
end
