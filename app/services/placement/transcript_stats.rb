module Placement::TranscriptStats
  # Fluency numbers from a transcript written with the placement convention: hesitation as "um"/"uh" and pauses over
  # 1 second as "…". Used for anchors, so they carry the same numbers recordings get from speech-to-text.
  FILLERS = %w[um uh].freeze

  def self.word_count(transcript)
    transcript.split.map { _1.downcase.gsub(/[^\p{L}\p{N}'.-]/, "").delete_suffix(".") }
      .count { !_1.empty? && !FILLERS.include?(_1) }
  end

  def self.long_pauses(transcript)
    transcript.count("…")
  end
end
