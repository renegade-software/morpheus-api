# Each form's YAML and clips live in their own folder under content/placement: form A at the top (the intake test),
# form B in form-b/ (the final test). The rubrics are shared, so every form is graded the same way.
module Placement::Import
  ROOT = Rails.root.join("content", "placement")
  RUBRIC_SOURCES = {
    "speaking" => "CEFR Table 3, Qualitative aspects of spoken language use (Council of Europe)",
    "writing" => "CEFR Companion Volume with New Descriptors (Council of Europe, 2018)"
  }.freeze

  def self.call(name:, folder: nil, purpose: "intake")
    dir = folder ? ROOT.join(folder) : ROOT
    Placement::Form.transaction do
      form = Placement::Form.create!(name: name, purpose: purpose)
      import_reading(form, dir)
      import_listening(form, dir)
      import_writing(form, dir)
      import_speaking(form, dir)
      import_rubrics(form)
      form
    end
  end

  def self.audio_dir(folder)
    (folder ? ROOT.join(folder) : ROOT).join("audio")
  end

  def self.import_reading(form, dir)
    read(dir, "reading.yaml").each do |text|
      passage = form.passages.create!(
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

  def self.import_listening(form, dir)
    read(dir, "listening.yaml").each do |clip|
      passage = form.passages.create!(
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
        end.join("\n"),
        display: clip.fetch("display", {})
      )

      create_question(passage, clip["question"], 1)

      audio = dir.join("audio", "listening-#{clip['tier']}.mp3")

      if audio.exist?
        passage.audio.attach(
          io: audio.open,
          filename: audio.basename.to_s,
          content_type: "audio/mpeg"
        )
      end
    end
  end

  def self.import_writing(form, dir)
    writing = read(dir, "writing.yaml")

    task = form.create_writing_task!(
      prompt: writing.dig("task", "situation"),
      seconds: writing.dig("task", "seconds"),
      bullets: writing.dig("task", "bullets"),
      scoring_rules: writing["scoring_rules"]
    )

    writing["anchors"].each do |anchor|
      task.writing_anchors.create!(
        level: level(anchor["level"]),
        text: anchor["text"],
        note: anchor["note"]
      )
    end
  end

  def self.import_speaking(form, dir)
    speaking = read(dir, "speaking.yaml")

    speaking["prompts"].each do |prompt|
      task = form.speaking_tasks.create!(
        tier: prompt["id"],
        reading_results: prompt["for_reading_result"],
        prompt: prompt["text"],
        seconds: speaking["seconds"],
        prep_seconds: speaking.fetch("prep_seconds"),
        retakes: speaking.fetch("retakes"),
        scoring_rules: speaking["scoring_rules"]
      )

      prompt["anchors"].each do |anchor|
        task.speaking_anchors.create!(
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
    read(ROOT, "rubrics.yaml").each do |skill, criteria|
      criteria.each do |criterion, levels|
        levels.each do |label, text|
          form.rubric_descriptors.create!(
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
    passage.questions.create!(
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

  def self.read(dir, file)
    YAML.safe_load_file(dir.join(file))
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
