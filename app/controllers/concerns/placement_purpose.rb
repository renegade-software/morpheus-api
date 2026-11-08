# Every placement endpoint serves either test: `?purpose=final` picks the optional final test, anything else the
# intake test, so the intake flow's requests stay as they were.
module PlacementPurpose
  extend ActiveSupport::Concern

  private

  def final_placement?
    params[:purpose] == "final"
  end

  def placement_attempt
    final_placement? ? current_participant.final_placement_attempt : current_participant.placement_attempt
  end
end
