# frozen_string_literal: true

# rbs_inline: enabled

require "faraday"

module VespaRuby
  class VespaResponse
    attr_reader :children #: Array[String]?
    attr_reader :request_body #: String?
    attr_reader :reason_phrase #: String?
    attr_reader :json #: Hash[String, untyped]
    attr_reader :status #: int?
    attr_reader :field_list #: Array[String]?
    attr_reader :total_count #: int?
    attr_reader :errors #: Array[untyped]?

    #: (::Faraday::Response) -> void
    def initialize(faraday_response)
      body = faraday_response.body

      @request_body = faraday_response.env&.request_body
      @json = body
      @status = faraday_response.status
      @total_count = body&.dig("root", "fields", "totalCount")
      @reason_phrase = faraday_response.reason_phrase
      @children = body&.dig("root", "children")
      @field_list = @children&.first&.dig("fields")&.keys
      @errors = body&.dig("root", "errors")
    end
  end
end
