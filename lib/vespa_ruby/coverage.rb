# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  # How much of the corpus a search covered: the response's root.coverage. A search
  # that hit Vespa's soft timeout answers HTTP 200 with the hits found so far and no
  # root.errors; only its coverage says the result set is partial
  # (https://docs.vespa.ai/en/reference/querying/default-result-format.html).
  class Coverage < Data.define(
    :percent, #: Integer? the share of documents searched, rounded (100 can still be partial)
    :documents, #: Integer? the documents searched
    :full, #: bool whether every document was searched (only an explicit true counts)
    :degraded #: Array[String] why not, from Vespa's flags: timeout, match-phase, adaptive-timeout, anntimeout, non-ideal-state
  )
    # nil when the body has no root.coverage (an error body, or none).
    #: (Hash[String, untyped]?) -> Coverage?
    def self.from_json(json)
      coverage = json&.dig("root", "coverage")
      return unless coverage

      degraded = coverage["degraded"]
      new(percent: coverage["coverage"], documents: coverage["documents"], full: coverage["full"] == true,
        degraded: degraded.is_a?(Hash) ? degraded.select { |_reason, set| set }.keys : [])
    end

    # The least complete of COVERAGES (nil entries ignored), for a search fanned out
    # over several requests: a partial one before a full one, then the lowest percent.
    # An entry without a percent loses to one with a known percent.
    #: (*Coverage?) -> Coverage?
    def self.least(*coverages)
      coverages.compact.min_by { |coverage| [coverage.partial? ? 0 : 1, coverage.percent || Float::INFINITY] }
    end

    #: () -> bool
    def partial? = !full || degraded.any?
  end
end
