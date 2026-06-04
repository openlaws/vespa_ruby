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

    test "ranking_profile is carried through build_request into post_body" do
      q = SimpleQuery.query("meal break")
        .select("id")
        .type("weakAnd")
        .restrict("division")
        .default_index("ranktext")
        .ranking_profile("bm25_anc_heavy")
        .where(WhereOp.contains("jurisdiction", "CA"))

      assert_equal "bm25_anc_heavy", q.ranking_profile_value

      request = q.build_request(options: {hits: 10})
      # rubocop:disable Style/HashSyntax
      assert_equal({:"ranking.profile" => "bm25_anc_heavy"}, request.ranking)
      # rubocop:enable Style/HashSyntax
      assert_equal "bm25_anc_heavy", request.post_body[:"ranking.profile"]
      assert_equal "ranktext", request.post_body[:"model.defaultIndex"]
    end
  end
end
