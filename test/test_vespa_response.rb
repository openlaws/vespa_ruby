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
  end
end
