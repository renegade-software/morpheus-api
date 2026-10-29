# A voice turn's word timings from the transcriber, for rhythm and pauses in feedback (FR6). Null on typed turns.
class AddWordsToConversationTurns < ActiveRecord::Migration[8.1]
  def change
    add_column :conversation_turns, :words, :jsonb
  end
end
