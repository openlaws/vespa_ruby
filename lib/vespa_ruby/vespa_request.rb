# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  class VespaRequest
    DEFAULT_HIT_LIMIT = 10

    attr_accessor :yql  #: String
    attr_accessor :hits, :offset, :timeout #: int
    attr_accessor :query_profile,
      :query_model,
      :ranking,
      :presentation,
      :tracing #: Hash[untyped, untyped]

    # TODO: Implement :grouping_session_cache, :search_chain, :ranking_matching, :ranking_match_phrase,
    # :grouping_aggregation, :streaming

    def initialize(yql, options: {})
      # Single values
      @yql = yql
      @hits = options[:hits] || DEFAULT_HIT_LIMIT
      @offset = options[:offset]
      @timeout = options[:timeout]

      # Hashes of values
      @query_profile = options[:query_profile] || {}
      @query_model = options[:query_model] || {}
      @ranking = options[:ranking] || {}
      @presentation = options[:presentation] || {}
      @tracing = options[:tracing] || {}
    end

    # Faraday expects a Hash
    #: () -> Hash[Symbol, untyped]
    def post_body
      result = {
        yql: @yql,
        hits: @hits,
        offset: @offset,
        timeout: @timeout
      }

      structures = [:query_profile,
        :query_model,
        :ranking,
        :presentation,
        :tracing]

      structures.each do |sym|
        result.merge! instance_variable_get(:"@#{sym}")
      end

      result.compact
    end

    def to_s
      "VespaRequest: body=#{post_body}"
    end
  end
end
