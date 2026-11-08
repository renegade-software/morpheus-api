class ConversationsController < ApplicationController
  before_action :require_eligible_consent!

  def create
    scenario = Scenario.current(params.expect(:scenario))
    return head :not_found unless scenario
    return render json: { errors: [ "not reached on the path yet" ] }, status: :forbidden unless
      LearningPath.can_play?(current_participant, scenario.key)

    Conversation.abandon_idle!(current_participant)

    render json: ConversationSerializer.new(Conversation.start!(current_participant, scenario)), status: :created
  end

  def show
    render json: ConversationSerializer.new(conversation)
  end

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
