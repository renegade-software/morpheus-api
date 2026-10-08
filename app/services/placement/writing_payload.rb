# The body of POST /placement/writing, built from the form the attempt is frozen to. Reading and listening results
# are left out on purpose, so they can't sway the rating.
module Placement::WritingPayload
  CRITERIA = %w[production range accuracy coherence].freeze

  def self.build(writing)
    task = writing.writing_task
    {
      text: writing.text.to_s,
      timed_out: writing.timed_out,
      task: { situation: task.prompt, bullets: task.bullets, scoring_rules: task.scoring_rules },
      anchors: task.writing_anchors.map { |anchor| { level: anchor.level, text: anchor.text, note: anchor.note } },
      rubric: rubric(task.form)
    }
  end

  # Descriptors grouped by criterion, as the agent expects. A missing criterion raises, so a broken form fails loudly.
  def self.rubric(form)
    descriptors = form.rubric_descriptors.where(skill: "writing").order(:level).group_by(&:criterion)
    CRITERIA.index_with { |criterion| descriptors.fetch(criterion).map { |d| { level: d.level, text: d.text } } }
  end
end
