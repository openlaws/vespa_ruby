# VespaRuby


## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add vespa_ruby

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install vespa_ruby

## Usage

### Connecting

```ruby
api = VespaRuby::Api.new          # base URL from ENV["VESPA_URL"], else http://localhost:8080
api = VespaRuby::Api.new("http://vespa.internal:8080", debug: true)

api.up?                           # => true / false (health check)
```

### Keyword search with `SimpleQuery`

`SimpleQuery` builds a Vespa [`userQuery()`](https://docs.vespa.ai/en/reference/query-language-reference.html#userquery)
request via a fluent chain, then `build_request` turns it into a request you hand to the API.

```ruby
query = VespaRuby::SimpleQuery.query("meal break")
  .select("id")                   # summary fields to return
  .type("weakAnd")                # all | any | weakAnd | tokenize | web | phrase
  .restrict("division")           # schema to search
  .where(VespaRuby::WhereOp.contains("jurisdiction", "CA"))

request  = query.build_request(options: { hits: 10 })
response = api.execute_search(request)

response.status        # => 200
response.total_count   # => total matches
response.children      # => array of hits, each with a "fields" hash
```

### Selecting a rank profile

Use `rank_profile` to score with a specific Vespa rank profile (the `ranking.profile`
request parameter). When unset, Vespa uses the schema's default profile. It composes with
`default_index` (handy when a profile scores fields outside the default fieldset):

```ruby
VespaRuby::SimpleQuery.query("meal break")
  .restrict("division")
  .default_index("ranktext")
  .rank_profile("bm25_anc_heavy")
  .where(VespaRuby::WhereOp.contains("jurisdiction", "CA"))
  .build_request(options: { hits: 10 })
```

### Building filter clauses with `WhereOp`

`WhereOp` produces YQL fragments for `where(...)`. Common operators: `contains`, `and`, `or`,
`not`, `range`, `lt`/`lte`/`gt`/`gte`/`eq`, `phrase`, `in`, `nearest_neighbor`.

```ruby
clause = VespaRuby::WhereOp.and(
  VespaRuby::WhereOp.contains("jurisdiction", "CA"),
  VespaRuby::WhereOp.contains("lawKey", "CA-LAB")
)
```

### Raw YQL with `YqlQuery`

For full control, build the YQL directly instead of relying on `userQuery()`:

```ruby
VespaRuby::YqlQuery
  .select("id", "name")
  .from("division")
  .where(VespaRuby::WhereOp.contains("name", "election"))
  .rank_profile("bm25_title3_anc2")
  .build_request(options: { hits: 25 })
```

### Advanced: raw request options

`build_request` accepts an `options` hash merged into the request body, so any parameter the
gem doesn't wrap is still reachable. The `rank_profile` setter is sugar over this and wins
on conflict; other `ranking.*` keys you pass through are preserved:

```ruby
query.build_request(options: {
  hits: 10,
  ranking: { "ranking.profile": "bm25_anc_heavy", "ranking.listFeatures": true }
})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Testing
`bundle exec rake test`

## Regenerating RBS signatures
`bundle exec rbs-inline lib/vespa_ruby --output`

Generated signatures are written to `sig/generated/` (the rbs-inline default). Hand-written
signatures (e.g. `sig/vespa_ruby.rbs`) live directly under `sig/` and are not overwritten.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/openlaws/vespa_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/openlaws/vespa_ruby/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the Apache 2.0 license.

## Code of Conduct

Everyone interacting in the VespaRuby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/vespa_ruby/blob/master/CODE_OF_CONDUCT.md).
