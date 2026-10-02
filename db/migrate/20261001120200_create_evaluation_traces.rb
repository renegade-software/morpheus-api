class CreateEvaluationTraces < ActiveRecord::Migration[8.1]
  def change
    create_table :evaluation_traces do |t|
      t.references :participant, null: false, foreign_key: true
      t.string  :step,          null: false
      t.string  :model,         null: false
      t.string  :effort
      t.string  :prompt_path,   null: false
      t.string  :prompt_sha256, null: false
      t.jsonb   :input
      t.jsonb   :output
      t.integer :input_tokens
      t.integer :output_tokens
      t.integer :latency_ms
      t.decimal :cost_usd, precision: 8, scale: 5
      t.string  :status, null: false
      t.text    :error

      t.timestamps
    end
  end
end
