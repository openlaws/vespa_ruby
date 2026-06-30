# frozen_string_literal: true

# rbs_inline: enabled

require "active_support/core_ext/object/blank"

module VespaRuby
  class SimpleQuery < YqlQuery
    # A weakAnd produced by the query parser (model.type=weakAnd + userQuery())
    # gets its targetHits from the requested `hits`, so ranking depends on the
    # page size: a larger `hits` widens the candidate pool and reshuffles the top
    # results, and because targetHits is per content node, deployments with
    # different node counts diverge too. We instead realize weakAnd via
    # weakAnd.replace + a fixed wand.hits, decoupling the candidate pool from the
    # page size so ranking is stable and reproducible. Large enough that the
    # per-node pool comfortably covers any page we return.
    DEFAULT_WEAK_AND_TARGET_HITS = 1000

    # See https://docs.vespa.ai/en/reference/query-api-reference.html#query-model
    # Not supporting model.encoding, model.locale, model.language, model.searchPath
    attr_reader :model_query_string_value,
      :model_default_index,
      :model_filter,
      :model_type, #: String?
      :target_hits_value #: Integer?

    def initialize
      @model_query_string_value = nil
      @model_default_index = nil
      @model_filter = nil
      @model_type = nil
      @target_hits_value = nil

      super
    end

    #: (String) -> YqlQuery
    def self.query(query_string)
      new.tap do |simple_query|
        simple_query.query(query_string)
      end
    end

    #: (String) -> YqlQuery
    def query(query_string)
      @model_query_string_value = query_string

      self
    end

    # Example 1:
    # input.query(myEmbedding)=embed(bert, "Hello world")
    #
    # Example 2:
    # {
    #    'yql': 'select title,url from wiki where {targetHits:10}nearestNeighbor(paragraph_embeddings, q)',
    #    'input.query(q)': 'embed(metric spaces)'
    # }
    #
    # Example 3: Hybrid search
    # {
    #    'yql': 'select title,url from wiki where (userQuery()) or ({targetHits:10}nearestNeighbor(paragraph_embeddings, q))',
    #    'input.query(q)': 'embed(metric spaces)',
    #    'query': 'metric spaces',
    #    'ranking': 'hybrid'
    # }
    #
    # Example 4:
    # vespa query 'yql=select * from doc where userQuery() or ({targetHits: 100}nearestNeighbor(embedding, e))' \
    #  'input.query(e)=embed(e5, "query: exchanging information by sound")' \
    #  'query=exchanging information by sound'
    def query_embedding
      # TODO: Implement above and determine if a separate EmbeddingQuery class is needed
    end

    #: (String) -> YqlQuery
    def default_index(default_index)
      @model_default_index = default_index

      self
    end

    #: (String) -> YqlQuery
    def filter(filter)
      @model_filter = filter

      self
    end

    # See https://docs.vespa.ai/en/reference/simple-query-language-reference.html
    #: (String) -> YqlQuery
    def type(type = "all")
      raise "Invalid type" unless %w[all any weakAnd tokenize web phrase].include?(type)

      @model_type = type

      self
    end

    # Override the fixed weakAnd targetHits (default DEFAULT_WEAK_AND_TARGET_HITS).
    # Only takes effect for weakAnd queries.
    #: (Integer) -> YqlQuery
    def target_hits(hits)
      @target_hits_value = hits

      self
    end

    #: () -> Hash[Symbol|String, untyped]
    def build_query_model_hash
      hash = {
        "model.queryString": @model_query_string_value,
        "model.defaultIndex": @model_default_index,
        "model.filter": @model_filter,
        "model.restrict": @model_restrict,
        "model.sources": @model_sources,
        "model.type": @model_type
      }

      # Realize weakAnd through weakAnd.replace so we control its targetHits (see
      # DEFAULT_WEAK_AND_TARGET_HITS). There is no Vespa knob for the targetHits of
      # the weakAnd that model.type=weakAnd + userQuery() generates, so instead we:
      #   1. model.type=any   -> userQuery() parses the terms into a plain OR
      #   2. weakAnd.replace  -> Vespa rewrites every OR in the tree into a weakAnd
      #   3. wand.hits=N      -> those rewritten weakAnds get a FIXED targetHits
      # Net: identical weakAnd matching, but the candidate pool is a constant N per
      # node instead of the page size.
      #
      # Caveat: weakAnd.replace is blunt -- it converts ALL ORs in the tree, incl.
      # any filter-side OR. Harmless here because a weakAnd with targetHits=N over a
      # few filter clauses never fills its heap, so it skips nothing and behaves
      # exactly like OR.
      if @model_type == "weakAnd"
        hash[:"model.type"] = "any"
        hash[:"weakAnd.replace"] = true
        hash[:"wand.hits"] = @target_hits_value || DEFAULT_WEAK_AND_TARGET_HITS
      end

      hash.compact
    end

    #: (Hash[untyped, untyped]) -> String
    def build_yql_string(options = {})
      return "" if @select_value.blank? && @from_value.blank? && @where_value.blank?

      # Simple query can also have a YQL
      @select_value ||= "select *"
      @from_value ||= "from sources *"

      if @where_value.blank?
        # Simple query was provided
        if @model_query_string_value.present?
          # Set where clause
          @where_value = "where userQuery()"
        end
      else # Append userQuery to existing where
        @where_value += " and userQuery()"
      end

      "#{@select_value} #{@from_value} #{@where_value} #{@order_by_value}".strip
    end

    #: (Hash[untyped, untyped]) -> VespaRequest
    def build_request(options: {})
      request_yql = build_yql_string
      VespaRequest.new(request_yql.present? ? request_yql : nil, options: options.merge({query_model: build_query_model_hash, ranking: build_ranking_hash(options)}))
    end
  end
end
