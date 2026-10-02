module CefrLevel
  LABELS = %w[A1 A2 B1 B2 C1 C2].freeze
  RANGE = 0..5

  def self.label(level)
    LABELS.fetch(level)
  end
end
