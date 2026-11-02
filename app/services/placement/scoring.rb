module Placement::Scoring
  TIER_LEVEL = [ 0.5, 2.0, 3.5, 4.5 ].freeze
  WEIGHTS = { speaking: 0.5, listening: 0.2, reading: 0.15, writing: 0.15 }.freeze
  WEIGHTS_WITHOUT_SPEAKING = { listening: 0.4, reading: 0.3, writing: 0.3 }.freeze

  def self.complete_if_ready(attempt)
    attempt.with_lock do
      return unless attempt.status == "scoring"
      return unless attempt.writing&.rated?
      return if Placement::Steps.voice_allowed?(attempt) && !attempt.recording&.rated?

      speaking = attempt.recording&.overall_level
      low, high, score = cefr_range(reading: attempt.reading_result, listening: attempt.listening_result,
                                    writing: attempt.writing.overall_level, speaking: speaking)
      attempt.update!(level_low: low, level_high: high, score: score, writing_level: attempt.writing.overall_level,
                      speaking_level: speaking, status: "completed", completed_at: Time.current)
      attempt.participant.update!(current_level: low, rank_points: RankPoints.from_placement(score))
    end
  end

  def self.cefr_range(reading:, listening:, writing:, speaking:)
    parts = { listening: TIER_LEVEL.fetch(listening), reading: TIER_LEVEL.fetch(reading), writing: writing }
    score = speaking ? weighted(parts.merge(speaking: speaking), WEIGHTS) : weighted(parts, WEIGHTS_WITHOUT_SPEAKING)
    low = score.floor.clamp(CefrLevel::RANGE.min, CefrLevel::RANGE.max - 1)
    [ low, low + 1, score ]
  end

  def self.weighted(parts, weights)
    weights.sum { |part, weight| weight * parts.fetch(part) }.round(2)
  end
end
