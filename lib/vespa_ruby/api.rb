# frozen_string_literal: true

# rbs_inline: enabled

require "faraday"
require "openssl"

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

    # Resolution for url/cert/key is: explicit arg > VespaRuby.config > (url only)
    # ENV["VESPA_URL"] > default. client_cert/client_key are PEM *contents*; when
    # both are present mutual TLS is enabled (e.g. Vespa Cloud), otherwise the
    # connection is plain HTTP — so local/self-hosted is unaffected.
    #: (?String?, ?debug: bool, ?timeout: Numeric, ?open_timeout: Numeric, ?client_cert: String?, ?client_key: String?) -> void
    def initialize(host_url = nil, debug: false, timeout: DEFAULT_TIMEOUT, open_timeout: DEFAULT_OPEN_TIMEOUT,
      client_cert: nil, client_key: nil)
      cfg = VespaRuby.config
      @url = host_url || cfg.url || ENV["VESPA_URL"] || "http://localhost:8080"
      cert = client_cert || cfg.client_cert
      key = client_key || cfg.client_key

      options = {url: @url}
      ssl = ssl_options(cert, key)
      options[:ssl] = ssl if ssl

      @conn = Faraday.new(**options) do |builder|
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

    private

    # Build Faraday SSL options for mutual TLS when both a client cert and key
    # (PEM contents) are given; nil otherwise (plain HTTP). OpenSSL::PKey.read
    # handles EC and RSA keys.
    #: (String?, String?) -> Hash[Symbol, untyped]?
    def ssl_options(cert, key)
      return nil if cert.nil? || cert.empty? || key.nil? || key.empty?

      {
        client_cert: OpenSSL::X509::Certificate.new(cert),
        client_key: OpenSSL::PKey.read(key)
      }
    end
  end
end
