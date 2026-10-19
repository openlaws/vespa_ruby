## [Unreleased]

## [0.5.3]

Every change below turns YQL that Vespa rejected (or that could carry injected YQL)
into valid, escaped YQL. Queries that worked on 0.5.2 render the same; what used to render
as invalid YQL (a `nil` member, an object's `to_s` as an annotation) now raises
`ArgumentError`.

- **Security:** `WhereOp.range`, `lt`/`lte`/`gt`/`gte`, and `eq` write only an Integer, a Float
  (not NaN), a BigDecimal (as `1.5`, not its `0.15e1`), a String holding a YQL number
  literal (`-1.5`, `.5`, `1e5`, `Infinity`/`-Infinity`) matched against the whole string,
  or a request parameter reference (`"@name"`). `range` checked bounds with `^…$`, so a
  bound with a line break (`"5\n) or true or …"`) passed; the comparisons didn't check
  their value at all, so `nil`, `Rational`, `Complex`, and NaN came out as `1/2`, `1+2i`,
  and `NaN`. A leading `+` is not YQL and raises.
- **Security:** annotation keys must be YQL identifiers (`stem`,
  `"hnsw.exploreAdditionalHits"`) and values a number, boolean, String, Symbol, nested
  Hash, or an Array of those; anything else raises. `build_annotations` wrote keys and
  non-String values with `to_s`, so a crafted key could add YQL to the query.
- **Security:** `WhereOp.eq` and `WhereOp.uri` escape their string values like
  `contains`.
- **Security:** control characters in string literals (a line break, a NUL) are written
  with the escapes YQL accepts (`\n`, `\u0000`, …) instead of as-is.
- `WhereOp.contains` writes every value as a quoted string literal. Vespa rejects a bare
  number or boolean after `contains` ("Cannot cast java.lang.Integer to
  java.lang.String") and matches `"5"` and `"true"` against int and bool fields, so
  `contains(field, 5)`, `contains(field, true)`, and the String `"true"` now work instead
  of failing. `nil`, Arrays, and Hashes raise `ArgumentError` instead of writing their
  `to_s` into the YQL.
- `WhereOp.uri` emits Vespa's `uri(…)`; `url(…)` was a YQL syntax error.
- `WhereOp.in` and `WhereOp.phrase` raise `ArgumentError` on an empty or missing set
  (`in ()` was a YQL syntax error; `in(f, nil)` raised `NoMethodError`) and on a `nil` or
  Array member, which used to be written as `""` or as the Array's `to_s`.
- `WhereOp.range` applies its `annotations:` (e.g. `{bounds: "leftOpen"}`), which it
  accepted and ignored.
- Documented that `rank`, `user_input`, `wand`, `weak_and`, and `nearest_neighbor` take
  YQL, written as given.
- `VespaResponse#coverage` returns the response's `root.coverage` as a
  `VespaRuby::Coverage`, or `nil` when the body has none. `partial?` is true when
  `full` is false or any `degraded` flag is set: a search Vespa's soft timeout cut
  short answers 200 with no `root.errors`, so coverage is the only sign.
  `Coverage.least` picks the least complete of several, for a search fanned out
  over more than one request.

## [0.5.2]

- **Security:** escape `"` and `\` in double-quoted YQL string literals
  (`QueryHelper#double_quoted_string` and `#quoted_array`). Previously a value
  containing a double quote — e.g. a caller passing user input as a `WhereOp.contains`,
  `WhereOp.in`, or `WhereOp.phrase` argument — could break out of the string literal and
  inject arbitrary YQL into the `where` clause. The free-text `model.queryString`
  (`userQuery()`) path was never affected; this only concerns values interpolated into
  the YQL string itself.

## [0.5.1]

- Fix `WhereOp.wand` raising `NoMethodError` instead of `ArgumentError` on fewer than two
  arguments (`ArgumentError(...)` called the class as a method; now `ArgumentError.new(...)`).

## [0.5.0]

- Add Vespa Cloud **data-plane access token** support (alternative to mTLS).
  `VespaRuby::Api.new(token:)` and `VespaRuby.configure { |c| c.token = ... }` set
  an `Authorization: Bearer <token>` header on every request. Resolution mirrors
  the other settings (explicit arg > config). Token auth targets Vespa Cloud's
  token endpoint; mTLS and token can be configured independently.
- Fix `VespaResponse` raising (`NoMethodError` on `String#dig`) when the response
  body isn't parsed JSON — e.g. a 403 from Vespa Cloud's data plane with a plain-text
  body. Such completed exchanges now return a `VespaResponse` with `#status` set
  (per the documented contract); the unparsed body is exposed via `#raw_body` and
  `#json` is nil.

## [0.4.0]

- Add opt-in mutual TLS (mTLS) for Vespa Cloud and a `VespaRuby.configure` block.
  `VespaRuby::Api.new` now accepts `client_cert:` / `client_key:` (PEM *contents*);
  when both are present the Faraday connection presents a client certificate,
  otherwise it stays plain HTTP (local/self-hosted unaffected).
- Add `VespaRuby.configure { |c| c.url = ...; c.client_cert = ...; c.client_key = ... }`
  for process-wide defaults (e.g. a Rails initializer). Resolution at `Api.new` is
  explicit arg > config > (url only) `ENV["VESPA_URL"]` > default. `client_cert`/
  `client_key` are sourced from config/args only — never read from ENV implicitly —
  so one process can target plain-HTTP local and mTLS cloud without env juggling.

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
