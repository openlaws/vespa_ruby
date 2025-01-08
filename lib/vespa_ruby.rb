# frozen_string_literal: true

require_relative "vespa_ruby/version"
require "zeitwerk"

module VespaRuby
  class Error < StandardError; end
  # Your code goes here...
end

loader = Zeitwerk::Loader.for_gem
loader.setup
