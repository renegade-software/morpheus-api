# The participant's own progress as a PDF to keep, from Settings: what Progreso shows, as text. It replaced the
# consent's offer of the study's general results (version 1.2).
# The wording comes from content/progress/labels.json: everything but "pdf" is copied from morpheus-ui
# src/locales/*/translation.json, so a changed title there needs copying here too.
class ProgressPdf
  LABELS = JSON.parse(Rails.root.join("content", "progress", "labels.json").read(encoding: "UTF-8")).freeze
  DEFAULT_LANGUAGE = "es".freeze
  TIME_ZONE = "America/Bogota".freeze
  SIZE = 9
  # Date, activity, mode, result, XP: 504pt, the width inside LETTER's 54pt margins.
  COLUMNS = [ 66, 222, 60, 116, 40 ].freeze
  PADDING = 4

  def self.render(participant)
    new(participant).render
  end

  def initialize(participant)
    @participant = participant
    @language = participant.display_language || DEFAULT_LANGUAGE
    @labels = LABELS.fetch(@language)
    @summary = Progress.summary(participant)
    @pdf = Prawn::Document.new(page_size: "LETTER", margin: 54, info: { Title: label("progress.title"), Creator: "Morpheus" })
  end

  def render
    @pdf.font("Helvetica", size: 10)
    @pdf.default_leading = 2
    header
    level
    skills
    history
    page_numbers
    @pdf.render
  end

  private

  def header
    @pdf.text label("progress.title"), size: 18, style: :bold
    @pdf.move_down 4
    @pdf.text label("pdf.generated", code: @participant.pseudonym, date: local(Time.current).strftime("%Y-%m-%d %H:%M")),
              size: 9, color: "48525C"
    @pdf.move_down 14
  end

  def level
    heading label("progress.level.title")
    line placement
    stage = @participant.stage
    line label("progress.level.stage", stage: label("stages.#{stage}"), total: Stage::KEYS.size) if stage
    line "#{label('progress.totalXp')}: #{Xp.summary(@participant).fetch(:total)}"
  end

  def placement
    band = @summary[:placement]
    return label("pdf.noPlacement") unless band

    low = CefrLevel.label(band[:level_low])
    high = CefrLevel.label(band[:level_high])
    return label("progress.level.placedAt", level: low) if low == high

    label("progress.level.placedBetween", low: low, high: high)
  end

  def skills
    heading label("progress.skills.title")
    line label("progress.skills.lead")
    @summary[:skills].each do |skill|
      score = skill[:score] ? label("progress.skills.value", score: decimal(skill[:score])) : label("progress.skills.none")
      bullet "<b>#{escape(label("skills.#{skill[:skill]}"))}:</b> #{escape(score)}"
    end
    @pdf.move_down 3
    line label("progress.skills.voiceNote")
  end

  # Newest first, like the table in Progreso.
  def history
    heading label("progress.history.title")
    steps = @summary[:history].reverse
    return line(label("pdf.noActivity")) if steps.empty?

    columns_header
    steps.each { row(cells(_1)) }
  end

  def columns_header
    row(%w[date activity mode result].map { label("progress.history.#{_1}") } + [ "XP" ], style: :bold)
  end

  def cells(step)
    [ local(step[:at]).strftime("%Y-%m-%d"), title(step), mode(step), result(step),
      step[:points].positive? ? "+#{step[:points]}" : "–" ]
  end

  def title(step)
    case step[:kind]
    when "review" then label("progress.history.review", stage: label("stages.#{step[:stage]}"))
    when "quiz" then label("progress.history.quiz", stage: label("stages.#{step[:stage]}"))
    else conversation_title(step)
    end
  end

  # Scenarios retired before the redesign have no title, so they fall back to the kind of activity, as in Progreso.
  def conversation_title(step)
    fallback = label(step[:mode] == "writing" ? "progress.history.writingTask" : "progress.history.conversation")
    title = @labels.fetch("scenarios")[step[:scenario]] || fallback
    step[:attempt] > 1 ? "#{title} #{label('progress.history.attempt', n: step[:attempt])}" : title
  end

  def mode(step)
    step[:kind] == "conversation" ? label("progress.history.modes.#{step[:mode]}") : ""
  end

  def result(step)
    case step[:kind]
    when "conversation" then label("progress.history.goals", met: step[:goals_met], total: step[:goals])
    when "quiz"
      label(step[:passed] ? "progress.history.quizPassed" : "progress.history.quizFailed",
            correct: step[:correct], total: step[:total])
    else ""
    end
  end

  # Prawn has no tables without another gem: each cell is a text box, and a row that doesn't fit starts a new page
  # with the column names again.
  def row(cells, style: :normal)
    height = cells.zip(COLUMNS).map { |cell, width| @pdf.height_of(cell, width: width - PADDING, size: SIZE, style: style) }.max
    if @pdf.cursor < height + PADDING
      @pdf.start_new_page
      columns_header unless style == :bold
    end

    top = @pdf.cursor
    x = 0
    cells.zip(COLUMNS).each_with_index do |(cell, width), index|
      @pdf.text_box cell, at: [ x, top ], width: width - PADDING, height: height, size: SIZE, style: style,
                          align: index == cells.size - 1 ? :right : :left
      x += width
    end
    @pdf.move_down height + PADDING
    @pdf.stroke_color "D9DEE2"
    @pdf.stroke_horizontal_rule
    @pdf.stroke_color "000000"
    @pdf.move_down PADDING
  end

  def heading(text)
    @pdf.start_new_page if @pdf.cursor < 90
    @pdf.move_down 8
    @pdf.text text, size: 12.5, style: :bold
    @pdf.move_down 5
  end

  def line(text)
    @pdf.text escape(text), inline_format: true
    @pdf.move_down 3
  end

  def bullet(markup)
    @pdf.indent(10) do
      @pdf.float { @pdf.text "•" }
      @pdf.indent(10) { @pdf.text markup, inline_format: true }
    end
    @pdf.move_down 3
  end

  def page_numbers
    @pdf.number_pages label("pdf.page"), at: [ @pdf.bounds.right - 60, -18 ], width: 60, align: :right, size: 8,
                                         color: "7F8C96"
  end

  # A dotted key into the labels, with {{name}} filled in the way i18next does in the UI.
  def label(key, **values)
    text = @labels.dig(*key.split("."))
    raise KeyError, "no #{@language} label #{key}" unless text.is_a?(String)

    values.reduce(text) { |filled, (name, value)| filled.gsub("{{#{name}}}", value.to_s) }
  end

  # 3.5 reads 3,5 in Spanish, as toLocaleString shows it in Progreso.
  def decimal(number)
    text = number.to_s.delete_suffix(".0")
    @language == "es" ? text.tr(".", ",") : text
  end

  def local(time)
    time.in_time_zone(TIME_ZONE)
  end

  # Prawn's inline format decodes only &amp;, &lt; and &gt;, so quotes stay as they are.
  def escape(text)
    text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end
end
