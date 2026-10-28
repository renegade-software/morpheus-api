class CreateFeedbacks < ActiveRecord::Migration[8.1]
  def change
    # One per finished conversation, written once by the agent. Its status lets the review screen poll while the
    # job runs. Dropped comments are only for the grounding analysis (NFR1), never shown, so they stay as JSON.
    create_table :feedbacks do |t|
      t.references :conversation, null: false, foreign_key: true, index: { unique: true }
      t.string :status, null: false, default: "pending"
      t.string :mode, null: false
      t.string :display_language, null: false
      t.text :summary
      t.jsonb :dropped, null: false, default: []
      t.references :evaluation_trace, foreign_key: true
      t.timestamps
    end

    # Rows, not JSON: FR10 counts categories across conversations and FR11 flags single comments. Each points at
    # the learner's turn its offsets slice, so the review screen always shows the stored text, never Claude's quote.
    create_table :feedback_comments do |t|
      t.references :feedback, null: false, foreign_key: true
      t.references :conversation_turn, null: false, foreign_key: true
      t.text :quote, null: false
      t.integer :start_offset, null: false
      t.integer :end_offset, null: false
      t.string :skill, null: false
      t.string :category, null: false
      t.string :priority, null: false
      t.text :explanation, null: false
      t.text :rewrite, null: false
      t.string :flagged_as
      t.timestamps
    end

    # A null score is FR9's "not enough evidence".
    create_table :feedback_scores do |t|
      t.references :feedback, null: false, foreign_key: true
      t.string :skill, null: false
      t.integer :score
      t.text :reason, null: false
      t.timestamps
      t.index %i[feedback_id skill], unique: true
    end
  end
end
