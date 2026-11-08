# The optional final test (form B, 2026-11-08) runs beside the intake test: each purpose has its own active form, and
# a participant gets one attempt per purpose. Passages gain `display`, the names the listening screen shows (tier a's
# caller, tier b's speaker turns), which were hardcoded in the UI for form A; form A's passages get them here.
class AddPurposeToPlacement < ActiveRecord::Migration[8.1]
  FORM_A_DISPLAY = {
    "a" => { caller: "Riverside Dental" },
    "b" => { turns: [ { speaker: "Priya", until: 7.65 }, { speaker: "Tom", until: 22.85 },
                      { speaker: "Priya", until: 28.6 }, { speaker: "Tom", until: nil } ] }
  }.freeze

  def up
    add_column :placement_forms, :purpose, :string, null: false, default: "intake"
    remove_index :placement_forms, name: "index_placement_forms_one_active"
    add_index :placement_forms, :purpose, unique: true, where: "status = 'active'", name: "index_placement_forms_one_active"

    add_column :placement_attempts, :purpose, :string, null: false, default: "intake"
    remove_index :placement_attempts, :participant_id
    add_index :placement_attempts, %i[participant_id purpose], unique: true

    add_column :placement_passages, :display, :jsonb, null: false, default: {}
    FORM_A_DISPLAY.each do |tier, display|
      execute <<~SQL.squish
        UPDATE placement_passages SET display = #{connection.quote(display.to_json)}::jsonb
        WHERE section = 'listening' AND tier = #{connection.quote(tier)}
      SQL
    end
  end

  def down
    remove_column :placement_passages, :display
    remove_index :placement_attempts, %i[participant_id purpose]
    add_index :placement_attempts, :participant_id, unique: true
    remove_column :placement_attempts, :purpose
    remove_index :placement_forms, name: "index_placement_forms_one_active"
    add_index :placement_forms, :status, unique: true, where: "status = 'active'", name: "index_placement_forms_one_active"
    remove_column :placement_forms, :purpose
  end
end
