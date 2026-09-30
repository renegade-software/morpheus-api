class Participant < ApplicationRecord
  before_validation :assign_pseudonym, on: :create

  validates :clerk_user_id, presence: true, uniqueness: true
  validates :pseudonym, presence: true, uniqueness: true

  def current_consent
    Consent.find_by(pseudonym: pseudonym, document_version: Consent::CURRENT_VERSION)
  end

  private

  # The pseudonym is the only identifier allowed in research data, so it must not derive from Clerk or the email.
  def assign_pseudonym
    self.pseudonym ||= "learner-#{SecureRandom.hex(4)}"
  end
end
