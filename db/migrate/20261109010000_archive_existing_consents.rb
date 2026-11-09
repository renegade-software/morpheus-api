# Consents signed before ArchiveConsentJob existed have no stored PDF. There's no shell on production, so the backfill
# runs once, on deploy. Only consents still without a PDF are queued, and the job skips any that got one meanwhile.
class ArchiveExistingConsents < ActiveRecord::Migration[8.1]
  # Migrations run while the old release is still serving, and its job worker doesn't know ArchiveConsentJob: a job
  # it picks up fails for good. By the time the wait is over, the new release has taken over.
  WAIT = 15.minutes

  def up
    Consent.where.missing(:pdf_attachment).find_each { ArchiveConsentJob.set(wait: WAIT).perform_later(_1) }
  end

  def down; end
end
