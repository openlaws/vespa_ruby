## [Unreleased]

## [0.3.0] - 2026-06-03

- **Breaking:** raise `required_ruby_version` to `>= 4.0.0` (was `>= 3.3.0`).
- Add `YqlQuery#ranking_profile` / `SimpleQuery#ranking_profile` fluent setter to
  select a Vespa rank-profile (request param `ranking.profile`). Composes with the
  existing raw `options[:ranking]` escape hatch (the setter wins on conflict).
- Dev toolchain: drop the `pry-byebug` development dependency; depend on `ostruct`,
  `cgi`, and `tsort` (removed from the Ruby 4.0/4.1 default gems but still needed by
  the test/lint tools) so the suite and `standardrb` run cleanly on Ruby 4.0.

## [0.1.0] - 2024-03-27

- Initial release
