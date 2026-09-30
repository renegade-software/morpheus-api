class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.timestamps

      t.string :clerk_user_id, null: false, index: { unique: true }
      t.string :pseudonym,     null: false, index: { unique: true }
    end
  end
end
