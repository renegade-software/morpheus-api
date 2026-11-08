require "net/http"

module Agent
  class Error < StandardError; end
  class Unavailable < Error; end
  # The model provider refused the account (no credits, bad key): failing now beats retrying for minutes.
  class Rejected < Error; end

  READ_TIMEOUT = 120
  # Feedback checks each voice note's pronunciation on the agent's CPU first, a few seconds per note (2026-11-08).
  FEEDBACK_READ_TIMEOUT = 600
  TURN_READ_TIMEOUT = 20
  OPEN_TIMEOUT = 5
  NETWORK_ERRORS = [ Net::OpenTimeout, Net::ReadTimeout, SocketError, EOFError, SystemCallError ].freeze

  def self.score_writing(payload)
    post("/placement/writing", payload)
  end

  def self.score_speaking(payload)
    post("/placement/speaking", payload)
  end

  def self.feedback(payload)
    post("/feedback", payload, read_timeout: FEEDBACK_READ_TIMEOUT)
  end

  def self.take_turn(payload)
    post("/conversation/turn", payload, read_timeout: TURN_READ_TIMEOUT)
  end

  def self.transcribe(payload)
    post("/conversation/transcribe", payload, read_timeout: TURN_READ_TIMEOUT)
  end

  def self.voice_reply(payload)
    post("/conversation/voice-reply", payload, read_timeout: TURN_READ_TIMEOUT)
  end

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
    raise Rejected, "agent answered #{status}: #{response.body.to_s.truncate(200)}" if status == 424

    raise Error, "agent answered #{status}: #{response.body.to_s.truncate(500)}"
  end
end
