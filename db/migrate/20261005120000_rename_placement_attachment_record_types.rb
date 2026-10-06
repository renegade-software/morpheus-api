class RenamePlacementAttachmentRecordTypes < ActiveRecord::Migration[8.1]
  RENAMES = { "PlacementPassage" => "Placement::Passage", "PlacementRecording" => "Placement::Recording" }.freeze

  def up
    RENAMES.each { |from, to| rename_record_type(from, to) }
  end

  def down
    RENAMES.each { |from, to| rename_record_type(to, from) }
  end

  private

  def rename_record_type(from, to)
    execute <<~SQL
      UPDATE active_storage_attachments SET record_type = #{connection.quote(to)} WHERE record_type = #{connection.quote(from)}
    SQL
  end
end
