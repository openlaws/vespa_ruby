# frozen_string_literal: true

require "test_helper"
# require "vespa_ruby/where_op"

module VespaRuby
  class TestSimpleQuery < ActiveSupport::TestCase
    test "initializes with query(...)" do
      q = SimpleQuery.query("keyword")

      assert q.is_a?(VespaRuby::SimpleQuery)
      assert_equal "keyword", q.model_query_string_value
    end

    #   $ vespa query 'select * from sources * where (vendor contains "brick and mortar" AND price < 50) AND userQuery()' \
    #   query="abc def -ghi" \
    #   type=all
    test "build_yql_hash with userQuery" do
      q = SimpleQuery.query("abc def -ghi")
        .type("all")
        .where(
          WhereOp.and(
            WhereOp.contains("vendor", "brick and mortar"),
            WhereOp.lt("price", 50)
          )
        )

      yql = q.build_yql_string

      assert_equal "select * from sources * where (vendor contains \"brick and mortar\" and price < 50) and userQuery()", yql
    end

    test "build_yql_hash with userQuery and no where" do
      q = SimpleQuery.query("abc def -ghi")
        .type("all").select("id").from("schema")
      yql = q.build_yql_string
      assert_equal "select id from schema where userQuery()", yql
    end

    test "build yql with query only" do
      q = SimpleQuery.query("abc def -ghi")
        .type("all")
      yql = q.build_yql_string
      assert_equal "", yql
    end
  end
end
