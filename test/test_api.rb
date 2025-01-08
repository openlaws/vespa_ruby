# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestApi < ActiveSupport::TestCase
    def setup
      @api = VespaRuby::Api.new
    end

    test "initialize" do
      assert_kind_of VespaRuby::Api, @api
      assert @api.conn.is_a?(Faraday::Connection)
      # assert_equal @api.url, "http://localhost:8080"
    end

    test "initialize with VESPA_URL" do
      url = "https://vespa-host:8080"
      ENV["VESPA_URL"] = url

      api = VespaRuby::Api.new
      assert_equal url, api.url

      ENV["VESPA_URL"] = nil
    end

    # Uses VCR test/cassettes/test_api
    test "up?" do
      assert @api.up?
    end

    test "raw search by POST" do
      yql = "select * from sources * where name contains 'Congress'"
      hits = 10

      post_body = {yql: yql, hits: hits}.to_json

      result = @api.raw_search_post(post_body)

      assert result
      assert_equal 200, result.status
      assert_equal 10, result.children.length
      assert_equal 618, result.total_count
    end

    test "execute_search yql" do
      yql_query = YqlQuery.select("*").from("sources *").where("name contains 'congress'")
      vespa_request = yql_query.build_request(options: {limit: 10})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 10, response.children.count
      assert_equal 618, response.total_count
      assert response.field_list.include?("documentid")
    end

    test "execute_search simple query" do
      simple_query = SimpleQuery.query("apples")
      vespa_request = simple_query.build_request(options: {hits: 5})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 5, response.children.count
      assert_equal 328, response.total_count
      assert response.field_list.include?("documentid")
    end

    test "execute_search simple query with yql" do
      simple_query = SimpleQuery.query("president commission").filter("-'pro tempore'")
        .select("id", "name", "lawKey", "path")
        .from("laws_content")
        .where(WhereOp.contains("jurisdiction", "FED"))
      vespa_request = simple_query.build_request(options: {hits: 10})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 200, response.status
      assert_equal 10, response.children.count
      assert_equal 3084, response.total_count
      assert response.field_list.include?("id")
      assert response.field_list.include?("name")
    end

    test "execute_search errors gets populated" do
      simple_query = SimpleQuery.query("")
      vespa_request = simple_query.build_request(options: {hits: 5})

      response = @api.execute_search(vespa_request)

      assert response.is_a?(VespaResponse)
      assert_equal 400, response.status
      assert_equal "Bad Request", response.reason_phrase
      assert_equal "No query", response.errors.first["message"]
    end
  end
end
