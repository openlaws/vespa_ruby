# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  class Vespa
    def self.query
      YqlQuery.new
    end
  end
end
