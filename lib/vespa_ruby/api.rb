# frozen_string_literal: true

# rbs_inline: enabled

require "faraday"

module VespaRuby
  class Api
    include VespaRuby::Loggable

    attr_reader :url  #: String
    attr_reader :conn #: ::Faraday::Connection
    attr_reader :debug #: bool

    #: (String?, bool) -> void
    def initialize(host_url = nil, debug: false)
      @url = ENV["VESPA_URL"] || host_url || "http://localhost:8080"

      @conn = Faraday.new(url: @url) do |builder|
        builder.request :json
        builder.response :json
      end

      @debug = debug
    end

    # See https://docs.vespa.ai/en/reference/healthchecks.html
    #: () -> bool
    def up?
      @conn.get("/status.html").status == 200
    end

    #: (VespaRequest) -> VespaResponse?
    def execute_search(vespa_request)
      logger.debug vespa_request.to_s if @debug

      response = @conn.post "/search/", vespa_request.post_body

      VespaResponse.new(response)
    end

    #: (String) -> VespaResponse?
    def raw_search_post(post_body)
      response = @conn.post("/search/", post_body)

      VespaResponse.new(response)
    rescue Faraday::Error => e
      logger.error("Faraday::Error #{e.response[:status]} #{e.response[:body]}")

      nil
    end
  end
end
