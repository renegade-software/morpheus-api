class ApplicationController < ActionController::API
  include Clerk::Authenticatable

  before_action :require_clerk_session!

  private

  def require_clerk_session!
    head :unauthorized unless clerk.user?
  end

  # create_or_find_by! leans on the unique index, so two first requests racing each other can't create duplicates.
  def current_participant
    @current_participant ||= Participant.find_by(clerk_user_id: clerk.user_id) ||
                             Participant.create_or_find_by!(clerk_user_id: clerk.user_id)
  end
end
