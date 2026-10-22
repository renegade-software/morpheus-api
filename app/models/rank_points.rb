# Rank points: the Elo-style score learners see while practising (Pelánek 2016, Computers & Education 98).
# It is not a CEFR level; only the placement test and the level tests set that.
module RankPoints
  # The placement score (A1 = 0 … C2 = 5) maps onto a chess-like range: A1 starts at 400, C2 ends at 2800, so
  # under 1000 is a beginner and over 2000 is very good. 400 per level is Elo's own scale, so one level apart
  # means the stronger side is expected to do about ten times better. 2.23 starts at 1292.
  BASE = 400
  PER_LEVEL = 400

  def self.from_placement(score)
    (BASE + PER_LEVEL * score).round
  end
end
