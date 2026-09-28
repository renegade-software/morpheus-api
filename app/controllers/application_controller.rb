class ApplicationController < ActionController::API
  include Clerk::Authenticatable

  before_action :require_clerk_session!

  private

  def require_clerk_session!
    head :unauthorized unless clerk.user?
  end
end
