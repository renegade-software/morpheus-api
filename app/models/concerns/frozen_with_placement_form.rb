module FrozenWithPlacementForm
  extend ActiveSupport::Concern

  def readonly?
    super || (persisted? && form.locked?)
  end
end
