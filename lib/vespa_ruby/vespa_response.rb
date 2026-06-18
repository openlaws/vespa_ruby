# frozen_string_literal: true

# rbs_inline: enabled

require "faraday"

module VespaRuby
  class VespaResponse
    attr_reader :children #: Array[untyped]?
    attr_reader :request_body #: String?
    attr_reader :reason_phrase #: String?
    attr_reader :json #: Hash[String, untyped]?
    attr_reader :raw_body #: untyped
    attr_reader :status #: int?
    attr_reader :field_list #: Array[String]?
    attr_reader :total_count #: int?
    attr_reader :errors #: Array[untyped]?

    #: (::Faraday::Response) -> void
    def initialize(faraday_response)
      @raw_body = faraday_response.body

      # Error responses (e.g. a 403 from Vespa Cloud's data plane) may carry a
      # non-JSON body (plain text, or none), in which case Faraday leaves it a
      # String. Only dig when we actually have a parsed Hash so any completed
      # exchange yields a populated #status instead of raising on String#dig.
      @json = @raw_body.is_a?(Hash) ? @raw_body : nil

      @request_body = faraday_response.env&.request_body
      @status = faraday_response.status
      @reason_phrase = faraday_response.reason_phrase
      @total_count = @json&.dig("root", "fields", "totalCount")
      @children = @json&.dig("root", "children")
      @field_list = @children&.first&.dig("fields")&.keys
      @errors = @json&.dig("root", "errors")
    end
  end
end
