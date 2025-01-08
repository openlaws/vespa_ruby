# frozen_string_literal: true

# rbs_inline: enabled

require "logger"

module VespaRuby
  module Loggable
    #: () -> ::Logger
    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end
