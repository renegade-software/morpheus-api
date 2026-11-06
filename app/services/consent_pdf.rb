# The participant's copy of the consent they signed: the document text of their version, then their answers.
# Built on request from the stored row, so there's no file to keep or delete. The text comes from
# content/consent/v<version>.json, exported from morpheus-ui src/consent/document*.ts.
class ConsentPdf
  DIR = Rails.root.join("content", "consent")
  TIME_ZONE = "America/Bogota".freeze
  ANSWER = { true => "Sí", false => "No" }.freeze

  MISSING = "No disponible".freeze

  # The email comes from Clerk at download time; the consents row keeps only the pseudonym.
  def self.render(consent, email:)
    new(consent, email).render
  end

  def initialize(consent, email)
    @consent = consent
    @email = email.presence || MISSING
    @document = JSON.parse(DIR.join("v#{consent.document_version}.json").read(encoding: "UTF-8"))
    @pdf = Prawn::Document.new(page_size: "LETTER", margin: 54, info: { Title: "Consentimiento informado", Creator: "Morpheus" })
  end

  def render
    @pdf.font("Helvetica", size: 10)
    @pdf.default_leading = 2
    header
    (@document.fetch("information") + @document.fetch("authorization")).each { section(_1) }
    record
    page_numbers
    @pdf.render
  end

  private

  def header
    @pdf.text "Consentimiento informado", size: 18, style: :bold
    @pdf.move_down 4
    @pdf.text "Copia de #{@email}. Versión #{@consent.document_version} del documento.",
              size: 9, color: "48525C"
    @pdf.move_down 14
  end

  def section(section)
    # A heading with no room for a few lines under it moves to the next page instead of ending this one.
    @pdf.start_new_page if @pdf.cursor < 90
    @pdf.move_down 8
    @pdf.text section.fetch("title"), size: 12.5, style: :bold
    @pdf.move_down 5
    section.fetch("blocks").each { block(_1) }
  end

  def block(block)
    case block.fetch("kind")
    when "paragraph" then paragraph(block["lead"], block.fetch("text"))
    when "list" then block.fetch("items").each { bullet(escape(_1)) }
    when "table" then table(block)
    when "link" then paragraph(nil, block.fetch("href"))
    when "contacts" then block.fetch("contacts").each { contact(_1) }
    when "question" then question(block)
    end
  end

  def paragraph(lead, text)
    body = escape(text)
    body = "<b>#{escape(lead)}</b> #{body}" if lead
    @pdf.text body, inline_format: true
    @pdf.move_down 6
  end

  def bullet(markup)
    @pdf.indent(10) do
      @pdf.float { @pdf.text "•" }
      @pdf.indent(10) { @pdf.text markup, inline_format: true }
    end
    @pdf.move_down 3
  end

  # Prawn has no tables without another gem, and these are short: one line per row, the first column in bold.
  def table(block)
    headers = block.fetch("headers")
    block.fetch("rows").each do |row|
      rest = row.drop(1).each_with_index.map { |cell, index| "#{escape(headers[index + 1])}: #{escape(cell)}" }
      bullet("<b>#{escape(row.first)}</b>. #{rest.join('. ')}.")
    end
    @pdf.move_down 3
  end

  def contact(contact)
    @pdf.text "<b>#{escape(contact.fetch('role'))}</b>", inline_format: true
    contact.fetch("lines").each { @pdf.text escape(_1), inline_format: true }
    @pdf.move_down 6
  end

  def question(block)
    answer = ANSWER.fetch(@consent.public_send(block.fetch("id")))
    bullet("#{escape(block.fetch('text'))} <b>Respuesta: #{answer}</b>")
  end

  def record
    @pdf.move_down 10
    @pdf.stroke_horizontal_rule
    @pdf.move_down 10
    @pdf.text "Registro de esta aceptación", size: 12.5, style: :bold
    @pdf.move_down 5
    accepted = @consent.accepted_at.in_time_zone(TIME_ZONE)
    [
      "<b>Correo electrónico:</b> #{escape(@email)}",
      "<b>Código de participante:</b> #{escape(@consent.pseudonym)}",
      "<b>Fecha y hora de la aceptación:</b> #{accepted.strftime('%Y-%m-%d %H:%M')} (hora de Colombia)",
      "<b>Versión del documento:</b> #{escape(@consent.document_version)}",
      "<b>Copia generada:</b> #{Time.current.in_time_zone(TIME_ZONE).strftime('%Y-%m-%d %H:%M')}"
    ].each { @pdf.text _1, inline_format: true }
  end

  def page_numbers
    @pdf.number_pages "<page> de <total>", at: [ @pdf.bounds.right - 60, -18 ], width: 60, align: :right, size: 8,
                                             color: "7F8C96"
  end

  # Prawn's inline format decodes only &amp;, &lt; and &gt;, so quotes stay as they are.
  def escape(text)
    text.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
  end
end
