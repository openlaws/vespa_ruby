# frozen_string_literal: true

# rbs_inline: enabled

require "faraday"

module VespaRuby
  class Api
    include VespaRuby::Loggable

    # Total read timeout (seconds) the client waits for a response.
    DEFAULT_TIMEOUT = 10
    # Timeout (seconds) the client waits to open the connection.
    DEFAULT_OPEN_TIMEOUT = 5

    attr_reader :url  #: String
    attr_reader :conn #: ::Faraday::Connection
    attr_reader :debug #: bool

    #: (?String?, ?debug: bool, ?timeout: Numeric, ?open_timeout: Numeric) -> void
    def initialize(host_url = nil, debug: false, timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT)
      @url = ENV["VESPA_URL"] || host_url || "http://localhost:8080"

      @conn = Faraday.new(url: @url) do |builder|
        builder.request :json
        builder.response :json
        builder.options.timeout = timeout
        builder.options.open_timeout = open_timeout
      end

      @debug = debug
    end

    # See https://docs.vespa.ai/en/reference/healthchecks.html
    #: () -> bool
    def up?
      @conn.get("/status.html").status == 200
    end

    # Returns a VespaResponse for any completed HTTP exchange, including
    # non-200 responses (check VespaResponse#status). Raises Faraday::Error
    # (e.g. Faraday::TimeoutError, Faraday::ConnectionFailed) on transport
    # failure; callers are expected to rescue it.
    #: (VespaRequest) -> VespaResponse
    def execute_search(vespa_request)
      logger.debug vespa_request.to_s if @debug

      response = @conn.post "/search/", vespa_request.post_body

      VespaResponse.new(response)
    end

    # See #execute_search for the return/raise contract: returns a
    # VespaResponse for any completed exchange and raises Faraday::Error on
    # transport failure.
    #: (String) -> VespaResponse
    def raw_search_post(post_body)
      response = @conn.post("/search/", post_body)

      VespaResponse.new(response)
    end
  end
end
