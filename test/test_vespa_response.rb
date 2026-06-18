# frozen_string_literal: true

require "test_helper"
require "faraday"

module VespaRuby
  class TestVespaResponse < ActiveSupport::TestCase
    def setup
      @faraday_response = ::Faraday::Response.new
      @response = VespaResponse.new(@faraday_response)
    end

    test "initialize" do
      assert_kind_of VespaResponse, @response
    end

    test "non-JSON error body (e.g. 403) yields status, not a raise" do
      env = ::Faraday::Env.from(status: 403, body: "Forbidden", reason_phrase: "Forbidden")
      response = VespaResponse.new(::Faraday::Response.new(env))

      assert_equal 403, response.status
      assert_equal "Forbidden", response.reason_phrase
      assert_equal "Forbidden", response.raw_body
      assert_nil response.json
      assert_nil response.children
      assert_nil response.total_count
      assert_nil response.errors
    end

    test "parsed JSON body exposes children/total_count/field_list" do
      body = {"root" => {"fields" => {"totalCount" => 5},
                         "children" => [{"fields" => {"name" => "x", "id" => "1"}}]}}
      env = ::Faraday::Env.from(status: 200, body: body)
      response = VespaResponse.new(::Faraday::Response.new(env))

      assert_equal 200, response.status
      assert_equal 5, response.total_count
      assert_equal 1, response.children.length
      assert_equal %w[name id], response.field_list
    end
  end
end
