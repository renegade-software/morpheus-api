class UsersController < ApplicationController
  def show
    render json: { user_id: clerk.user_id, pseudonym: current_participant.pseudonym }
  end
end
