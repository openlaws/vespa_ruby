# frozen_string_literal: true

# rbs_inline: enabled

require "active_support"

module VespaRuby
  class SimpleQuery < YqlQuery
    # See https://docs.vespa.ai/en/reference/query-api-reference.html#query-model
    # Not supporting model.encoding, model.locale, model.language, model.searchPath
    attr_reader :model_query_string_value,
      :model_default_index,
      :model_filter,
      :model_type #: String?

    def initialize
      @model_query_string_value = nil
      @model_default_index = nil
      @model_filter = nil
      @model_type = nil

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

    # TODO: Add {targetHits: #{params[:limit] * 10}} to weakAnd queries. Default is 100.
    # See https://docs.vespa.ai/en/reference/simple-query-language-reference.html
    #: (String) -> YqlQuery
    def type(type = "all")
      raise "Invalid type" unless %w[all any weakAnd tokenize web phrase].include?(type)

      @model_type = type

      self
    end

    #: () -> Hash[Symbol|String, String?]?
    def build_query_model_hash
      {
        "model.queryString": @model_query_string_value,
        "model.defaultIndex": @model_default_index,
        "model.filter": @model_filter,
        "model.restrict": @model_restrict,
        "model.sources": @model_sources,
        "model.type": @model_type
      }.compact!
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
      VespaRequest.new(request_yql.present? ? request_yql : nil, options: options.merge({query_model: build_query_model_hash}))
    end
  end
end
