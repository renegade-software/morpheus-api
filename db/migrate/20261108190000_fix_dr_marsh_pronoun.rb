# Form A's radio interview is voiced by a man, but its question's options said "She" (reported 2026-11-08). Only the
# wording changes; the order and the answer key stay, so recorded responses are unaffected.
class FixDrMarshPronoun < ActiveRecord::Migration[8.1]
  SHE = [
    "She thinks they go further than the evidence, although the lanes have some value",
    "She agrees that the lanes have been a great success",
    "She thinks the lanes have been a waste of money"
  ].freeze
  HE = SHE.map { _1.sub(/\AShe /, "He ") }.freeze

  def up
    swap(SHE, HE)
  end

  def down
    swap(HE, SHE)
  end

  private

  def swap(from, to)
    execute <<~SQL.squish
      UPDATE placement_questions SET options = #{connection.quote(to.to_json)}::jsonb
      WHERE options = #{connection.quote(from.to_json)}::jsonb
    SQL
  end
end
