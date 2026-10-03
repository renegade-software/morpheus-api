module Placement::Import
  # Builds a draft form in the item bank from the authoring files in content/placement/. The app never reads those
  # files at runtime; once imported and activated, the database is the only source of the test.

  DIR = Rails.root.join("content", "placement")
  AUDIO_DIR = DIR.join("audio")
  RUBRIC_SOURCES = {
    "speaking" => "CEFR Table 3, Qualitative aspects of spoken language use (Council of Europe)",
    "writing" => "CEFR Companion Volume with New Descriptors (Council of Europe, 2018)"
  }.freeze

  def self.call(name:)
    PlacementForm.transaction do
      form = PlacementForm.create!(name: name)
      import_reading(form)
      import_listening(form)
      import_writing(form)
      import_speaking(form)
      import_rubrics(form)
      form
    end
  end

  def self.import_reading(form)
    read("reading.yaml").each do |text|
      passage = form.placement_passages.create!(
        section: "reading",
        tier: text["tier"],
        level: level(text["level"]),
        seconds: text["seconds"],
        cefr_scale: text["scale"],
        cefr_descriptor: text["descriptor"],
        body: text["text"]
      )

      text["questions"].each.with_index(1) do |question, position|
        create_question(passage, question, position)
      end
    end
  end

  def self.import_listening(form)
    read("listening.yaml").each do |clip|
      passage = form.placement_passages.create!(
        section: "listening",
        tier: clip["tier"],
        level: level(clip["level"]),
        cefr_scale: clip["scale"],
        cefr_descriptor: clip["descriptor"],
        delivery: clip["delivery"],
        plays: clip["plays"],
        seconds: clip["seconds"],
        transcript: clip["lines"].map do |line|
          "#{line['speaker']}: #{line['text']}"
        end.join("\n")
      )

      create_question(passage, clip["question"], 1)

      audio = AUDIO_DIR.join("listening-#{clip['tier']}.mp3")

      if audio.exist?
        passage.audio.attach(
          io: audio.open,
          filename: audio.basename.to_s,
          content_type: "audio/mpeg"
        )
      end
    end
  end

  def self.import_writing(form)
    writing = read("writing.yaml")

    task = form.create_placement_writing_task!(
      prompt: writing.dig("task", "situation"),
      seconds: writing.dig("task", "seconds"),
      bullets: writing.dig("task", "bullets"),
      scoring_rules: writing["scoring_rules"]
    )

    writing["anchors"].each do |anchor|
      task.placement_writing_anchors.create!(
        level: level(anchor["level"]),
        text: anchor["text"],
        note: anchor["note"]
      )
    end
  end

  def self.import_speaking(form)
    speaking = read("speaking.yaml")

    speaking["prompts"].each do |prompt|
      task = form.placement_speaking_tasks.create!(
        tier: prompt["id"],
        reading_results: prompt["for_reading_result"],
        prompt: prompt["text"],
        seconds: speaking["seconds"],
        scoring_rules: speaking["scoring_rules"]
      )

      prompt["anchors"].each do |anchor|
        task.placement_speaking_anchors.create!(
          level: level(anchor["level"]),
          transcript: anchor["transcript"],
          note: anchor["note"],
          speaking_ms: anchor["speaking_seconds"] * 1000,
          word_count: Placement::TranscriptStats.word_count(anchor["transcript"]),
          long_pauses: Placement::TranscriptStats.long_pauses(anchor["transcript"])
        )
      end
    end
  end

  def self.import_rubrics(form)
    read("rubrics.yaml").each do |skill, criteria|
      criteria.each do |criterion, levels|
        levels.each do |label, text|
          form.placement_rubric_descriptors.create!(
            skill: skill,
            criterion: criterion,
            level: level(label),
            text: text,
            source: RUBRIC_SOURCES.fetch(skill)
          )
        end
      end
    end
  end

  def self.create_question(passage, question, position)
    passage.placement_questions.create!(
      position: position,
      prompt: question["prompt"],
      options: question["options"],
      correct_option: question["answer"],
      targets: question["targets"]
    )
  end

  def self.level(label)
    CefrLevel::LABELS.index(label) || raise(ArgumentError, "unknown CEFR level #{label.inspect}")
  end

  def self.read(file)
    YAML.safe_load_file(DIR.join(file))
  end

  private_class_method :import_reading,
                        :import_listening,
                        :import_writing,
                        :import_speaking,
                        :import_rubrics,
                        :create_question,
                        :level,
                        :read
end
