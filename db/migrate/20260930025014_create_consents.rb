class CreateConsents < ActiveRecord::Migration[8.1]
  def change
    # Keyed by pseudonym, not a foreign key, so the record survives participant deletion as proof of authorization.
    # One column per Sí / No question in the committee-approved document; a new document version means a new migration.
    create_table :consents do |t|
      t.string   :pseudonym,        null: false, index: true
      t.string   :document_version, null: false
      t.boolean  :adult,            null: false
      t.boolean  :participate,      null: false
      t.boolean  :personal_data,    null: false
      t.boolean  :sensitive_data,   null: false
      t.boolean  :audio_recording,  null: false
      t.boolean  :transcription,    null: false
      t.boolean  :receive_results,  null: false
      t.datetime :accepted_at,      null: false

      t.timestamps
    end
  end
end
