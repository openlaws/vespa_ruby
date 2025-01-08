# frozen_string_literal: true

require_relative "lib/vespa_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "vespa_ruby"
  spec.version = VespaRuby::VERSION
  spec.authors = ["John Phamvan"]
  spec.email = ["john@openlaws.us"]

  spec.summary = "Ruby Vespa API client and YQL query builder"
  spec.homepage = "https://github.com/openlaws/vespa_ruby"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.3.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/openlaws/vespa_ruby"
  spec.metadata["changelog_uri"] = "https://github.com/openlaws/vespa_ruby/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "activesupport"
  spec.add_dependency "faraday", "~> 2.9.0"
  spec.add_dependency "logging"
  spec.add_dependency "zeitwerk"

  spec.add_development_dependency "minitest"
  spec.add_development_dependency "pry-byebug", "~> 3.10.1"
  spec.add_development_dependency "rbs-inline"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "standard", "~> 1.3"
  spec.add_development_dependency "vcr", "~> 6.2"
  spec.add_development_dependency "webmock", "~> 3.23"
end
