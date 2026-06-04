# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in vespa_ruby.gemspec
gemspec

gem "rake", "~> 13.0"

# Ruby 4.0 dropped these from the default gems but the dev/test toolchain still needs
# them: rbs/json require ostruct; vcr uses CGI.parse from cgi. tsort is required by
# rubocop (standard) and rbs, and is removed from defaults in Ruby 4.1.
gem "ostruct"
gem "cgi"
gem "tsort"
