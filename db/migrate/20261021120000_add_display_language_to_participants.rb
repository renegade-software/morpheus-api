class AddDisplayLanguageToParticipants < ActiveRecord::Migration[8.1]
  def change
    # Chosen once the placement result is in. Empty until then, which is also how the app knows
    # the learner hasn't left the result screen yet.
    add_column :participants, :display_language, :string
  end
end
