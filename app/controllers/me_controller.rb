class MeController < ApplicationController
  def show
    render json: { user_id: clerk.user_id }
  end
end
