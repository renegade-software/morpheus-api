# The twelve stages of the path, two per CEFR level, in order. Keys match morpheus-ui src/path/stages.ts.
module Stage
  KEYS = %w[firstSteps onFoot path crossing bridge firmFooting lookout bend longRoad goodPace summit beyond].freeze
  PER_LEVEL = 2

  def self.first_for(level)
    KEYS.fetch(level * PER_LEVEL)
  end

  def self.level_of(key)
    KEYS.index(key) / PER_LEVEL
  end

  def self.after(key)
    KEYS[KEYS.index(key) + 1]
  end
end
