# Turns the placement parts into the learner's CEFR range, once every part they did is rated.
module Placement::Scoring
  # Reading and listening give 0–3, the tier reached; each maps to the middle of the band it points to
  # (decided 2026-10-07). Writing and speaking are already levels, 0–5.
  TIER_LEVEL = [ 0.5, 2.0, 3.5, 4.5 ].freeze
  WEIGHTS = { speaking: 0.5, listening: 0.2, reading: 0.15, writing: 0.15 }.freeze
  # No voice consent: speaking's half spread over the rest in proportion, and writing sets the low end instead
  # (decided 2026-10-07).
  WEIGHTS_WITHOUT_SPEAKING = { listening: 0.4, reading: 0.3, writing: 0.3 }.freeze

  # Called by both rating jobs; whichever finishes last completes the attempt. The lock stops two jobs finishing
  # together from both completing it.
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
      # Practice starts at the bottom of the range; the intake range on the attempt never changes.
      attempt.participant.update!(current_level: low)
    end
  end

  # A range, never one level, so a short test never claims more precision than it has. Returns [low, high, score].
  def self.cefr_range(reading:, listening:, writing:, speaking:)
    parts = { listening: TIER_LEVEL.fetch(listening), reading: TIER_LEVEL.fetch(reading), writing: writing }
    if speaking
      score = weighted(parts.merge(speaking: speaking), WEIGHTS)
      anchor = speaking # speaking decides where the learner starts
    else
      score = weighted(parts, WEIGHTS_WITHOUT_SPEAKING)
      anchor = writing
    end
    low = [ score.floor, anchor ].min
    high = [ score.ceil, low + 1 ].max.clamp(CefrLevel::RANGE.min, CefrLevel::RANGE.max)
    [ low, high, score ]
  end

  # Rounded so float noise (2.5000000000000004) can't push a whole-number score up a level when ceil is taken.
  def self.weighted(parts, weights)
    weights.sum { |part, weight| weight * parts.fetch(part) }.round(2)
  end
end
