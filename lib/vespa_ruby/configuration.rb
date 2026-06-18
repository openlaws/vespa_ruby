# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  # Process-wide defaults for VespaRuby::Api, set via VespaRuby.configure. Explicit
  # VespaRuby::Api.new arguments still override these. All values are nil unless
  # configured. client_cert / client_key are PEM *contents* (not file paths) and
  # enable mutual TLS (e.g. Vespa Cloud); leave them nil for plain HTTP. token is a
  # Vespa Cloud data-plane access token sent as `Authorization: Bearer <token>`
  # (used against the token endpoint, an alternative to mTLS).
  class Configuration
    attr_accessor :url         #: String?
    attr_accessor :client_cert #: String?
    attr_accessor :client_key  #: String?
    attr_accessor :token       #: String?
  end
end
