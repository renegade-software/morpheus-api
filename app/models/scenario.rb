# A version of one scenario's content, frozen once created: what the character was given, kept for every conversation
# that ran on it (NFR6). New versions come from content/scenarios/ through `bin/rails scenarios:import`.
class Scenario < ApplicationRecord
  STATUSES = %w[active retired].freeze
  # Text chat or voice notes: decides which skills feedback covers (text leaves out rhythm and pronunciation).
  MODES = %w[text voice].freeze
  DIR = Rails.root.join("content", "scenarios")
  INTERLOCUTOR_FILE = "interlocutor.yaml"
  CHARACTERS_FILE = Rails.root.join("content", "characters.yaml")

  has_many :conversations, dependent: :restrict_with_exception
  # A voice version's opening line in the character's pinned voice, the same for every conversation on it. It isn't
  # learner data, so it lives on the version rather than on anyone's turns.
  has_one_attached :opening_audio

  validates :key, :content, :content_sha256, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :level, inclusion: { in: CefrLevel::RANGE }
  validates :turn_limit, numericality: { only_integer: true, greater_than: 0 }

  # A version is evidence: once conversations ran on it, its content must never change.
  before_update { raise ActiveRecord::ReadOnlyRecord, "scenario content is frozen" if content_changed? }

  def self.current(key)
    find_by(key: key, status: "active")
  end

  # Imports every scenario file. A file whose content (with its level's descriptors and its character) is already
  # stored is skipped; a changed one becomes a new active version and retires the old one. Returns the versions it
  # created.
  def self.import_all!
    interlocutor = YAML.load_file(DIR.join(INTERLOCUTOR_FILE))
    characters = YAML.load_file(CHARACTERS_FILE)
    DIR.glob("*.yaml").reject { _1.basename.to_s == INTERLOCUTOR_FILE }.filter_map do |path|
      import!(YAML.load_file(path), interlocutor, characters)
    end
  end

  def self.import!(file, interlocutor, characters)
    level = file.fetch("level")
    descriptors = interlocutor.fetch(level) { raise ArgumentError, "no interlocutor descriptors for level #{level}" }
    key = file.fetch("character")
    character = characters.fetch(key) { raise ArgumentError, "no character #{key} in #{CHARACTERS_FILE.basename}" }
    # The agent reads one "You are: …" line, so the frozen scenario carries the name and this scenario's role together.
    scenario = file.except("role").merge("character" => "#{character.fetch('name')}, #{file.fetch('role')}")
    content = { "scenario" => scenario, "character" => character.merge("key" => key),
                "interlocutor" => descriptors.map { { "level" => level, "text" => _1 } } }
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

  def needs_opening_audio?
    mode == "voice" && !opening_audio.attached?
  end

  # Made once per version by `scenarios:import`, through the agent. Agent errors propagate, so the import can simply
  # be run again. Returns the synthesis trace for the import to report.
  def voice_opening!
    response = Agent.synthesize(voice_id: content.fetch("character").fetch("voice"), text: opening)
    opening_audio.attach(io: StringIO.new(Base64.strict_decode64(response.fetch("audio"))),
                         filename: "#{key}-#{id}-opening.mp3", content_type: response.fetch("content_type"))
    response.fetch("trace")
  end

  def goal_ids
    content.dig("scenario", "goals").map { _1.fetch("id") }
  end
end
