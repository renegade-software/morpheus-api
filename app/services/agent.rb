require "net/http"

# Talks to morpheus-agent, which owns every Claude call. Only Rails holds AGENT_TOKEN, so only Rails can use it.
module Agent
  # A setup problem (bad token, malformed body): retrying won't help, so the job fails and shows the error.
  class Error < StandardError; end
  # Busy, restarting or unreachable: the scoring jobs retry these with growing waits; a conversation turn tells the
  # learner to try again.
  class Unavailable < Error; end

  # A rating takes about 10–20 s; this leaves room for a slow provider without hanging a worker forever.
  READ_TIMEOUT = 120
  # A character's turn answers while the learner waits (NFR3, 3 s); past this they're better off trying again.
  TURN_READ_TIMEOUT = 20
  OPEN_TIMEOUT = 5
  NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, SocketError, EOFError, SystemCallError ].freeze

  def self.score_writing(payload)
    post("/placement/writing", payload)
  end

  def self.score_speaking(payload)
    post("/placement/speaking", payload)
  end

  # A finished conversation's feedback; a background job, so it gets the rating timeout, not the turn's.
  def self.feedback(payload)
    post("/feedback", payload)
  end

  def self.take_turn(payload)
    post("/conversation/turn", payload, read_timeout: TURN_READ_TIMEOUT)
  end

  # Transcription, the character's turn and its voice in one call; budgeted at 6 s (NFR3), same cut-off as text.
  def self.take_voice_turn(payload)
    post("/conversation/voice-turn", payload, read_timeout: TURN_READ_TIMEOUT)
  end

  # One line in a character's voice: a voice scenario's opening, made at import.
  def self.synthesize(payload)
    post("/speech", payload, read_timeout: TURN_READ_TIMEOUT)
  end

  def self.post(path, body, read_timeout: READ_TIMEOUT)
    uri = URI.join(ENV.fetch("AGENT_URL"), path)
    request = Net::HTTP::Post.new(uri, "Content-Type" => "application/json",
                                       "Authorization" => "Bearer #{ENV.fetch("AGENT_TOKEN")}")
    request.body = body.to_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                   open_timeout: OPEN_TIMEOUT, read_timeout: read_timeout) do |http|
      http.request(request)
    end
    parse(response)
  rescue *NETWORK_ERRORS => error
    raise Unavailable, "#{error.class}: #{error.message}"
  end

  def self.parse(response)
    status = response.code.to_i
    return JSON.parse(response.body) if status == 200
    raise Unavailable, "agent answered #{status}" if status == 429 || status >= 500

    raise Error, "agent answered #{status}: #{response.body.to_s.truncate(500)}"
  end
end
