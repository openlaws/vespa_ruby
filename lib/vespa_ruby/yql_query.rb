# frozen_string_literal: true

# rbs_inline: enabled

require "active_support"

module VespaRuby
  class YqlQuery
    include VespaRuby::QueryHelper

    attr_reader :select_value,
      :from_value,
      :where_value,
      :order_by_value,
      :model_restrict,
      :model_sources #: String

    def initialize
      @select_value ||= nil
      @from_value ||= nil
      @where_value ||= nil
      @order_by_value ||= nil
      @model_restrict ||= nil
      @model_sources ||= nil
    end

    #: (*String) -> YqlQuery
    def self.select(*fields)
      new.tap do |yql_query|
        yql_query.select(*fields)
      end
    end

    #: (*String) -> YqlQuery
    def select(*fields)
      @select_value = fields.empty? ? "select *" : "select #{fields.join(", ")}"

      self
    end

    #: (*String) -> YqlQuery
    def from(*sources)
      @from_value = sources.empty? ? "from sources *" : "from #{sources.join(", ")}"

      self
    end

    #: (String) -> YqlQuery
    def where(clause)
      raise "Missing where clause" unless clause.present?

      @where_value = "where #{clause}"

      self
    end

    #: (String) -> YqlQuery
    def restrict(restrict)
      @model_restrict = restrict

      self
    end

    #: (String) -> YqlQuery
    def sources(sources)
      @model_sources = sources

      self
    end

    #: (*String, Hash[untyped, untyped]) -> YqlQuery
    def order_by(*attribute_order_pairs, annotations: {})
      @order_by_value = "order by #{attribute_order_pairs.join(", ")}"

      self
    end

    #: () -> Hash[String, String]
    def build_query_model_hash
      {
        "model.restrict": @model_restrict,
        "model.sources": @model_sources
      }.compact!
    end

    #: () -> String
    def build_yql_string
      raise "Query missing select" unless @select_value.present?
      raise "Query missing from" unless @from_value.present?
      raise "Query missing where" unless @where_value.present?

      return "#{@select_value} #{@from_value} #{@where_value} #{@order_by_value}" if @order_by_value.present?

      "#{@select_value} #{@from_value} #{@where_value}"
    end

    #: (Hash[untyped, untyped]) -> VespaRequest
    def build_request(options: {})
      VespaRequest.new(build_yql_string, options: options.merge({query_model: build_query_model_hash}))
    end
  end
end
