# How the conversation was actually played. A voice scenario runs as a typed chat for a learner who didn't consent to
# audio, so the mode belongs to the conversation, not the scenario. Null on older rows, which used the scenario's.
class AddModeToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :mode, :string
  end
end
