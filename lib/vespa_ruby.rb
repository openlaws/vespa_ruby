# frozen_string_literal: true

require_relative "vespa_ruby/version"
require "zeitwerk"

# Core extensions used across the gem (blank?/present?/presence). Required here
# so the gem works standalone, not just when Rails has already loaded them.
require "active_support/core_ext/object/blank"

module VespaRuby
  class Error < StandardError; end

  class << self
    # Process-wide configuration (see VespaRuby::Configuration). Lazily created.
    #: () -> Configuration
    def config = (@config ||= Configuration.new)

    # Set defaults, e.g. in a Rails initializer:
    #   VespaRuby.configure { |c| c.url = ENV["VESPA_URL"]; c.client_cert = ... }
    #: () { (Configuration) -> void } -> void
    def configure = yield(config)

    # Reset configuration to defaults (primarily for tests).
    #: () -> void
    def reset_config! = (@config = Configuration.new)
  end
end

loader = Zeitwerk::Loader.for_gem
loader.setup
