class AddOnboardedAtToParticipants < ActiveRecord::Migration[8.1]
  def change
    # When the learner finished or skipped the onboarding on Inicio. Kept on the account, not in the browser,
    # so it doesn't show again on a new device.
    add_column :participants, :onboarded_at, :datetime
  end
end
