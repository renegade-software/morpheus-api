class SplitPlacementTasksByKind < ActiveRecord::Migration[8.1]
  # Copies tasks and anchors into the per-kind tables with the same ids, so existing forms keep their content
  # (no re-import) and placement_writings and placement_recordings only need their column renamed.
  def up
    execute <<~SQL
      INSERT INTO placement_writing_tasks (id, placement_form_id, prompt, bullets, seconds, scoring_rules, created_at, updated_at)
      SELECT id, placement_form_id, prompt, bullets, seconds, scoring_rules, created_at, updated_at
      FROM placement_tasks WHERE kind = 'writing';

      INSERT INTO placement_speaking_tasks (id, placement_form_id, tier, reading_results, prompt, follow_up, seconds, scoring_rules, created_at, updated_at)
      SELECT id, placement_form_id, tier, reading_results, prompt, follow_up, seconds, scoring_rules, created_at, updated_at
      FROM placement_tasks WHERE kind = 'speaking';

      INSERT INTO placement_writing_anchors (id, placement_writing_task_id, level, text, note, created_at, updated_at)
      SELECT a.id, a.placement_task_id, a.level, a.text, a.note, a.created_at, a.updated_at
      FROM placement_anchors a JOIN placement_tasks t ON t.id = a.placement_task_id
      WHERE t.kind = 'writing';

      INSERT INTO placement_speaking_anchors (id, placement_speaking_task_id, level, transcript, note, speaking_seconds, created_at, updated_at)
      SELECT a.id, a.placement_task_id, a.level, a.text, a.note, a.speaking_seconds, a.created_at, a.updated_at
      FROM placement_anchors a JOIN placement_tasks t ON t.id = a.placement_task_id
      WHERE t.kind = 'speaking';
    SQL

    # The copied ids were set by hand, so move each sequence past them.
    %w[placement_writing_tasks placement_speaking_tasks placement_writing_anchors placement_speaking_anchors].each do |table|
      reset_pk_sequence!(table)
    end

    remove_foreign_key :placement_writings, :placement_tasks
    rename_column :placement_writings, :placement_task_id, :placement_writing_task_id
    add_foreign_key :placement_writings, :placement_writing_tasks

    remove_foreign_key :placement_recordings, :placement_tasks
    rename_column :placement_recordings, :placement_task_id, :placement_speaking_task_id
    add_foreign_key :placement_recordings, :placement_speaking_tasks

    drop_table :placement_anchors
    drop_table :placement_tasks
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
