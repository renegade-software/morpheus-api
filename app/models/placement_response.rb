class PlacementResponse < ApplicationRecord
  SECTIONS = %w[reading listening].freeze
  OPTIONS = 0..2

  belongs_to :placement_attempt

  validates :section, inclusion: { in: SECTIONS }
  validates :item_key, presence: true, uniqueness: { scope: :placement_attempt_id }
  validates :selected_option, inclusion: { in: OPTIONS }, allow_nil: true
  validates :correct, inclusion: { in: [ true, false ] }
  validates :shown_at, presence: true

  # The browser runs the timers; a question left unanswered when time ran out arrives with no option.
  def timed_out?
    selected_option.nil?
  end
end
