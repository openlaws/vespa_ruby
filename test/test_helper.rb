# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "vespa_ruby"

require "active_support"
require "active_support/test_case"
require "minitest/autorun"
require "pry-byebug"

# Load everything from test/support
::Dir.glob(::File.expand_path("../support/**/*.rb", __FILE__)).each { |f| require_relative f }
