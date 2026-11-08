# There's no shell on production, so form B (the optional final test) is imported and activated here, on deploy, the
# way the build imports scenarios. Skipped where the form already exists, so it's safe on any database.
class ImportFinalPlacementForm < ActiveRecord::Migration[8.1]
  NAME = "2026-11 final"

  def up
    Placement::Form.reset_column_information
    Placement::Attempt.reset_column_information
    Placement::Passage.reset_column_information
    return if Placement::Form.exists?(name: NAME)

    Placement::Import.call(name: NAME, folder: "form-b", purpose: "final").activate!
  end

  # Only while nobody has taken it; after that the form is part of the study's data.
  def down
    form = Placement::Form.find_by(name: NAME)
    return unless form
    raise ActiveRecord::IrreversibleMigration, "#{NAME} has attempts" if form.attempts.exists?

    form.destroy!
  end
end
