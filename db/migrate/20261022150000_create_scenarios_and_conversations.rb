class CreateScenariosAndConversations < ActiveRecord::Migration[8.1]
  def change
    # One row per version of a scenario's content. A version is frozen once created, so every conversation keeps
    # pointing at exactly what the character was given (NFR6).
    create_table :scenarios do |t|
      t.string :key, null: false
      t.integer :level, null: false
      t.integer :turn_limit, null: false
      t.jsonb :content, null: false # the agent's Scenario plus the level's interlocutor descriptors
      t.string :content_sha256, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :scenarios, :content_sha256, unique: true
    add_index :scenarios, :key, unique: true, where: "status = 'active'", name: "index_scenarios_on_key_when_active"

    # Learner text throughout, so it belongs to the participant and is deleted with them.
    create_table :conversations do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :scenario, null: false, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :finished_reason
      t.jsonb :goals, null: false, default: [] # the agent's latest goal checks
      t.datetime :finished_at
      t.timestamps
    end

    create_table :conversation_turns do |t|
      t.references :conversation, null: false, foreign_key: true
      t.integer :position, null: false # 0 is the character's opening
      t.string :speaker, null: false
      t.text :text, null: false
      # The character's turns point at the call that wrote them; the learner's and the opening have none.
      t.references :evaluation_trace, foreign_key: true
      t.timestamps
    end
    add_index :conversation_turns, %i[conversation_id position], unique: true

    add_reference :evaluation_traces, :conversation, foreign_key: true
  end
end
