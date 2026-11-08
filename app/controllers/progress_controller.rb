class ProgressController < ApplicationController
  # GET /progress
  def show
    render json: Progress.summary(current_participant)
  end
end
