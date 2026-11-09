class ProgressController < ApplicationController
  # GET /progress
  def show
    render json: Progress.summary(current_participant)
  end

  # GET /progress/pdf: the same progress as a PDF the participant keeps, in their display language.
  def pdf
    send_data ProgressPdf.render(current_participant), type: "application/pdf", disposition: "attachment",
                                                       filename: "progreso-#{current_participant.pseudonym}.pdf"
  end
end
