class AlignEvaluationTracesWithAgentTrace < ActiveRecord::Migration[8.1]
  def change
    change_column_null :evaluation_traces, :model, true
    change_column_null :evaluation_traces, :prompt_path, true
    change_column_null :evaluation_traces, :prompt_sha256, true
    add_column :evaluation_traces, :retried, :boolean, null: false, default: false
    add_reference :evaluation_traces, :placement_attempt, foreign_key: true
  end
end
