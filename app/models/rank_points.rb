module RankPoints
  BASE = 400
  PER_LEVEL = 400

  def self.from_placement(score)
    (BASE + PER_LEVEL * score).round
  end
end
