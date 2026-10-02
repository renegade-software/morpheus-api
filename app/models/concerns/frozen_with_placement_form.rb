# Content in a form that has been activated never changes, so every response keeps pointing at the exact wording
# the learner saw. A correction means importing a new form.
module FrozenWithPlacementForm
  extend ActiveSupport::Concern

  def readonly?
    super || (persisted? && placement_form.locked?)
  end
end
