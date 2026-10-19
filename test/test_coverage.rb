# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestCoverage < ActiveSupport::TestCase
    # root.coverage as Vespa sends it for a search its soft timeout cut short.
    TIMED_OUT = {"coverage" => 86, "documents" => 3987856, "full" => false, "nodes" => 1, "results" => 1, "resultsFull" => 0,
                 "degraded" => {"match-phase" => false, "timeout" => true, "adaptive-timeout" => false, "anntimeout" => false,
                                "non-ideal-state" => false}}.freeze
    FULL = {"coverage" => 100, "documents" => 4644430, "full" => true, "nodes" => 1, "results" => 1, "resultsFull" => 1}.freeze

    test "a timed-out search is partial, with its reason" do
      coverage = Coverage.from_json(body_with(TIMED_OUT))

      assert coverage.partial?
      assert_equal 86, coverage.percent
      assert_equal 3987856, coverage.documents
      assert_equal ["timeout"], coverage.degraded
    end

    test "a full search is not partial" do
      refute Coverage.from_json(body_with(FULL)).partial?
    end

    test "coverage rounded to 100 is still partial when not full" do
      assert Coverage.from_json(body_with(FULL.merge("full" => false))).partial?
    end

    test "coverage without full is partial, and a degraded that isn't a Hash is no flags" do
      assert Coverage.from_json(body_with(TIMED_OUT.except("full"))).partial?
      assert Coverage.from_json(body_with(FULL.except("full"))).partial?

      coverage = Coverage.from_json(body_with(TIMED_OUT.merge("degraded" => "timeout")))
      assert_equal [], coverage.degraded
      assert coverage.partial?
    end

    test "a body without coverage has none" do
      assert_nil Coverage.from_json(body_with(nil))
      assert_nil Coverage.from_json(nil)
    end

    test "least picks the partial one, then the lower percent" do
      full = Coverage.from_json(body_with(FULL))
      partial = Coverage.from_json(body_with(TIMED_OUT))
      worse = Coverage.from_json(body_with(TIMED_OUT.merge("coverage" => 57)))

      assert_equal partial, Coverage.least(full, partial)
      assert_equal worse, Coverage.least(partial, nil, worse)
      assert_nil Coverage.least(nil, nil)
    end

    test "least prefers a known percent over a missing one" do
      unknown = Coverage.from_json(body_with(TIMED_OUT.except("coverage")))
      partial = Coverage.from_json(body_with(TIMED_OUT))

      assert_equal partial, Coverage.least(unknown, partial)
      assert_equal partial, Coverage.least(partial, unknown)
      assert_equal unknown, Coverage.least(unknown, Coverage.from_json(body_with(FULL)))
    end

    private

    def body_with(coverage)
      root = {"fields" => {"totalCount" => 1}}
      root["coverage"] = coverage if coverage
      {"root" => root}
    end
  end
end
