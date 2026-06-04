# frozen_string_literal: true

require_relative "vespa_ruby/version"
require "zeitwerk"

# Core extensions used across the gem (blank?/present?/presence). Required here
# so the gem works standalone, not just when Rails has already loaded them.
require "active_support/core_ext/object/blank"

module VespaRuby
  class Error < StandardError; end
  # Your code goes here...
end

loader = Zeitwerk::Loader.for_gem
loader.setup
