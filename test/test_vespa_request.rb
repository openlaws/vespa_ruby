# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestVespaRequest < ActiveSupport::TestCase
    def setup
      @yql = "select * from sources * where true"
      @user_query_yql = "select * from sources * where userQuery()"
      @options = {}
      @complex_options = {
        hits: 10,
        offset: 0,
        timeout: 5,
        query_model: {
          "model.defaultIndex": "default",
          "model.filter": "-durian",
          "model.queryString": "apples oranges bananas"
        },
        ranking: {
          "ranking.profile": "default"
        },
        tracing: {
          "trace.level": 3
        }
      }
      @request = VespaRequest.new(@yql, options: @options)
    end

    test "initialize" do
      assert_kind_of VespaRequest, @request
    end

    test "basic post_body" do
      yql_request = @request.post_body
      expected_yql_hash = {
        yql: "select * from sources * where true",
        hits: 10
      }
      assert_equal yql_request, expected_yql_hash
    end

    test "more complex request post_body" do
      complex_request = VespaRequest.new(@user_query_yql, options: @complex_options)
      expected_hash = {
        yql: @user_query_yql,
        hits: 10,
        offset: 0,
        timeout: 5,
        "model.defaultIndex": "default",
        "model.filter": "-durian",
        "model.queryString": "apples oranges bananas",
        "ranking.profile": "default",
        "trace.level": 3
      }
      assert_equal expected_hash, complex_request.post_body
    end
  end
end
