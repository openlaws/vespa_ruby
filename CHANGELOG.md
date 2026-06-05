## [Unreleased]

## [0.3.0] - 2026-06-03

- **Breaking:** raise `required_ruby_version` to `>= 4.0.0` (was `>= 3.3.0`).
- Add configurable client-side HTTP timeouts to `Api.new` via `timeout:`
  (total read timeout) and `open_timeout:` keyword args, defaulting to
  `DEFAULT_TIMEOUT` (10s) and `DEFAULT_OPEN_TIMEOUT` (5s). Previously the
  Faraday connection had no timeout, so a hung request could block
  indefinitely; a stalled call now raises `Faraday::TimeoutError`.
- **Breaking:** `Api#raw_search_post` now raises `Faraday::Error` on transport
  failure instead of logging and returning `nil`, matching `Api#execute_search`.
  Both methods now share one contract: return a `VespaResponse` for any
  completed exchange (check `#status`), raise `Faraday::Error` (including
  `Faraday::TimeoutError`) otherwise.
- Fix standalone (non-Rails) use: require `active_support/core_ext/object/blank`
  from the entrypoint so `build_request` no longer raises `NoMethodError` for
  `blank?`/`present?`. Previously the gem only required bare `active_support`,
  which does not load these core extensions, so it relied on Rails having loaded
  them globally.
- Add `YqlQuery#rank_profile` / `SimpleQuery#rank_profile` fluent setter to
  select a Vespa rank-profile (request param `ranking.profile`). Composes with the
  existing raw `options[:ranking]` escape hatch (the setter wins on conflict).
- Dev toolchain: drop the `pry-byebug` development dependency; depend on `ostruct`,
  `cgi`, and `tsort` (removed from the Ruby 4.0/4.1 default gems but still needed by
  the test/lint tools) so the suite and `standardrb` run cleanly on Ruby 4.0.

## [0.1.0] - 2024-03-27

- Initial release
