class AddFluencyNumbersToPlacementSpeakingAnchors < ActiveRecord::Migration[8.1]
  # Anchors get the same fluency numbers, names and units as placement_recordings, so Claude compares like with like.
  # Existing anchors are counted from their transcripts, which mark hesitation with "um"/"uh" and pauses over 1 s
  # with "…". The counting is copied here rather than calling app code, so this migration keeps working if that changes.
  FILLERS = %w[um uh].freeze

  def up
    add_column :placement_speaking_anchors, :speaking_ms, :integer
    add_column :placement_speaking_anchors, :word_count, :integer
    add_column :placement_speaking_anchors, :long_pauses, :integer

    select_rows("SELECT id, transcript, speaking_seconds FROM placement_speaking_anchors").each do |id, transcript, seconds|
      execute <<~SQL
        UPDATE placement_speaking_anchors
        SET speaking_ms = #{Integer(seconds) * 1000}, word_count = #{word_count(transcript)},
            long_pauses = #{transcript.count('…')}
        WHERE id = #{Integer(id)}
      SQL
    end

    change_column_null :placement_speaking_anchors, :speaking_ms, false
    change_column_null :placement_speaking_anchors, :word_count, false
    change_column_null :placement_speaking_anchors, :long_pauses, false
    remove_column :placement_speaking_anchors, :speaking_seconds
  end

  def down
    add_column :placement_speaking_anchors, :speaking_seconds, :integer
    execute "UPDATE placement_speaking_anchors SET speaking_seconds = speaking_ms / 1000"
    change_column_null :placement_speaking_anchors, :speaking_seconds, false
    remove_column :placement_speaking_anchors, :speaking_ms
    remove_column :placement_speaking_anchors, :word_count
    remove_column :placement_speaking_anchors, :long_pauses
  end

  private

  def word_count(transcript)
    transcript.split.map { _1.downcase.gsub(/[^\p{L}\p{N}'.-]/, "").delete_suffix(".") }
      .count { !_1.empty? && !FILLERS.include?(_1) }
  end
end
