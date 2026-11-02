module Placement::TranscriptStats
  FILLERS = %w[um uh].freeze

  def self.word_count(transcript)
    transcript.split.map { _1.downcase.gsub(/[^\p{L}\p{N}'.-]/, "").delete_suffix(".") }
      .count { !_1.empty? && !FILLERS.include?(_1) }
  end

  def self.long_pauses(transcript)
    transcript.count("…")
  end
end
