# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in vespa_ruby.gemspec
gemspec

gem "rake", "~> 13.0"

# Security floor: pull in uri only transitively (via activesupport/net-http), but
# pin the minimum to the patched release so the lockfile can't resolve below it.
gem "uri", ">= 0.13.2"

# Ruby 4.0 dropped these from the default gems but the dev/test toolchain still needs
# them: rbs/json require ostruct; vcr uses CGI.parse from cgi. tsort is required by
# rubocop (standard) and rbs, and is removed from defaults in Ruby 4.1.
gem "ostruct"
gem "cgi"
gem "tsort"
