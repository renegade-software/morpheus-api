# A clean start for the study (2026-11-08): production held only Andy's own and test accounts, and the experiment's
# data, model traces included, should start from nothing. There's no shell on production, so it runs once, on deploy.
# Every participant's data goes, with their recordings in storage; the study content (scenarios, placement forms)
# stays. Production only, so local test data survives a migrate.
class WipeUserDataBeforeStudy < ActiveRecord::Migration[8.1]
  # Everything that hangs off a participant. Truncated together, so the foreign keys between them don't matter.
  USER_TABLES = %w[
    feedback_comments feedback_scores feedbacks
    conversation_turns conversations
    placement_responses placement_writings placement_recordings placement_attempts
    stage_quiz_attempts stage_reviews
    evaluation_traces consents participants
  ].freeze

  # Learner audio: voice notes and placement answers. Scenario openings and passage audio are study content.
  LEARNER_AUDIO = %w[Conversation::Turn Placement::Recording].freeze

  def up
    return unless Rails.env.production?

    # Files first: if storage fails, the deploy fails with the tables intact, and the next deploy tries again.
    ActiveStorage::Attachment.where(record_type: LEARNER_AUDIO).includes(:blob).find_each(&:purge)
    ActiveStorage::Blob.unattached.find_each(&:purge)

    execute "TRUNCATE #{USER_TABLES.join(', ')} RESTART IDENTITY"
    # Ids start again from 1, so a leftover job (a feedback retry, say) must not run against a new learner's record.
    execute "TRUNCATE solid_queue_jobs RESTART IDENTITY CASCADE"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
