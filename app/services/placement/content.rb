module Placement
  # Reads the placement items from content/placement/*.yaml. Answer keys, notes, anchors and rubrics live in the same
  # files, so nothing from here goes to the browser except through StepPresenter, which picks fields explicitly.
  module Content
    DIR = Rails.root.join("content", "placement")
    FILES = %w[reading.yaml listening.yaml writing.yaml speaking.yaml rubrics.yaml].freeze

    def self.reading
      @reading ||= load("reading.yaml").index_by { _1["tier"] }
    end

    def self.listening
      @listening ||= load("listening.yaml").index_by { _1["tier"] }
    end

    def self.writing
      @writing ||= load("writing.yaml")
    end

    def self.speaking
      @speaking ||= load("speaking.yaml")
    end

    def self.speaking_prompt_for(reading_result)
      speaking["prompts"].find { _1["for_reading_result"].include?(reading_result) }
    end

    # Item keys look like "reading.b.q2" or "listening.c" and match the keys the presenter sends.
    def self.question(item_key)
      section, tier, number = item_key.split(".")
      case section
      when "reading" then reading.fetch(tier)["questions"].fetch(Integer(number.delete_prefix("q")) - 1)
      when "listening" then listening.fetch(tier)["question"]
      else raise KeyError, "unknown placement item #{item_key}"
      end
    end

    # Stored on each attempt, so results can be traced to the exact item wording a learner saw, even after edits.
    def self.version
      @version ||= Digest::SHA256.hexdigest(FILES.map { DIR.join(_1).read }.join)[0, 12]
    end

    def self.load(file)
      YAML.safe_load_file(DIR.join(file))
    end
    private_class_method :load
  end
end
