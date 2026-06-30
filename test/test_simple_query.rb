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

    test "rank_profile is carried through build_request into post_body" do
      q = SimpleQuery.query("meal break")
        .select("id")
        .type("weakAnd")
        .restrict("division")
        .default_index("ranktext")
        .rank_profile("bm25_anc_heavy")
        .where(WhereOp.contains("jurisdiction", "CA"))

      assert_equal "bm25_anc_heavy", q.rank_profile_value

      request = q.build_request(options: {hits: 10})
      # rubocop:disable Style/HashSyntax
      assert_equal({:"ranking.profile" => "bm25_anc_heavy"}, request.ranking)
      # rubocop:enable Style/HashSyntax
      assert_equal "bm25_anc_heavy", request.post_body[:"ranking.profile"]
      assert_equal "ranktext", request.post_body[:"model.defaultIndex"]
    end

    test "weakAnd uses a fixed targetHits decoupled from hits" do
      q = SimpleQuery.query("qualified business income deduction")
        .select("id").from("division").type("weakAnd")
        .where(WhereOp.contains("jurisdiction", "FED"))

      b1 = q.build_request(options: {hits: 1}).post_body
      b50 = q.build_request(options: {hits: 50}).post_body

      # weakAnd is realized via weakAnd.replace so its targetHits is controllable
      assert_equal "any", b1[:"model.type"]
      assert_equal true, b1[:"weakAnd.replace"]

      # the bug: targetHits tracked hits. Now it must NOT change with the page size
      assert_equal b1[:"wand.hits"], b50[:"wand.hits"]
      # ...and be large enough that the pool isn't the page size
      assert_operator b50[:"wand.hits"], :>=, 500
      # the page size itself still varies as requested
      assert_equal 1, b1[:hits]
      assert_equal 50, b50[:hits]
    end

    test "target_hits overrides the default weakAnd targetHits" do
      q = SimpleQuery.query("meal break").select("id").from("division")
        .type("weakAnd").target_hits(2000)

      assert_equal 2000, q.build_request(options: {hits: 20}).post_body[:"wand.hits"]
    end

    test "non-weakAnd queries emit no weakAnd params" do
      body = SimpleQuery.query("meal break").select("id").from("division")
        .type("all").build_request(options: {hits: 20}).post_body

      assert_equal "all", body[:"model.type"]
      assert_nil body[:"weakAnd.replace"]
      assert_nil body[:"wand.hits"]
    end
  end
end
