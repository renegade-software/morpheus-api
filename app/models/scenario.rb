# A version of one scenario's content, frozen once created: what the character was given, kept for every conversation
# that ran on it (NFR6). New versions come from content/scenarios/ through `bin/rails scenarios:import`.
class Scenario < ApplicationRecord
  STATUSES = %w[active retired].freeze
  # Text chat or voice notes: decides which skills feedback covers (text leaves out rhythm and pronunciation).
  MODES = %w[text voice].freeze
  DIR = Rails.root.join("content", "scenarios")
  INTERLOCUTOR_FILE = "interlocutor.yaml"

  has_many :conversations, dependent: :restrict_with_exception

  validates :key, :content, :content_sha256, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :level, inclusion: { in: CefrLevel::RANGE }
  validates :turn_limit, numericality: { only_integer: true, greater_than: 0 }

  # A version is evidence: once conversations ran on it, its content must never change.
  before_update { raise ActiveRecord::ReadOnlyRecord, "scenario content is frozen" if content_changed? }

  def self.current(key)
    find_by(key: key, status: "active")
  end

  # Imports every scenario file. A file whose content (with its level's descriptors) is already stored is skipped;
  # a changed one becomes a new active version and retires the old one. Returns the versions it created.
  def self.import_all!
    interlocutor = YAML.load_file(DIR.join(INTERLOCUTOR_FILE))
    DIR.glob("*.yaml").reject { _1.basename.to_s == INTERLOCUTOR_FILE }.filter_map do |path|
      import!(YAML.load_file(path), interlocutor)
    end
  end

  def self.import!(scenario, interlocutor)
    level = scenario.fetch("level")
    descriptors = interlocutor.fetch(level) { raise ArgumentError, "no interlocutor descriptors for level #{level}" }
    content = { "scenario" => scenario, "interlocutor" => descriptors.map { { "level" => level, "text" => _1 } } }
    sha256 = Digest::SHA256.hexdigest(JSON.generate(content))
    return if exists?(content_sha256: sha256)

    transaction do
      where(key: scenario.fetch("id"), status: "active").update_all(status: "retired", updated_at: Time.current)
      create!(key: scenario.fetch("id"), level: level, turn_limit: scenario.fetch("turn_limit"),
              content: content, content_sha256: sha256)
    end
  end

  # The leeway past the turn limit while a goal is still open, as the agent counts it (models.extra_turns).
  def extra_turns
    (turn_limit / 4.0).ceil
  end

  # Versions imported before scenarios named their mode were all text chats.
  def mode
    content.dig("scenario", "mode") || "text"
  end

  def opening
    content.dig("scenario", "opening")
  end

  def goal_ids
    content.dig("scenario", "goals").map { _1.fetch("id") }
  end
end
