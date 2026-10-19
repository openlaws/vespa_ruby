require "test_helper"
require "bigdecimal"

module VespaRuby
  class TestWhereOp < ActiveSupport::TestCase
    test "contains" do
      op_contains = WhereOp.contains("a", "A")
      assert_equal "a contains \"A\"", op_contains

      # Vespa rejects a bare number or boolean after contains and matches the quoted
      # form against int and bool fields.
      assert_equal "a contains \"1\"", WhereOp.contains("a", 1)
      assert_equal "a contains \"true\"", WhereOp.contains("a", "true")
      assert_equal "a contains \"false\"", WhereOp.contains("a", false)
      assert_equal "a contains \"b\"", WhereOp.contains("a", :b)
    end

    test "contains raises on nil and collections instead of writing their to_s" do
      assert_raises(ArgumentError) { WhereOp.contains("a", nil) }
      assert_raises(ArgumentError) { WhereOp.contains("a", ["x\" or true or \""]) }
      assert_raises(ArgumentError) { WhereOp.contains("a", {b: 1}) }
    end

    test "contains escapes a value that tries to break out of the string literal" do
      # Without escaping this injects a second clause: a contains "x" or true or "".
      op = WhereOp.contains("a", "x\" or true or \"")
      assert_equal "a contains \"x\\\" or true or \\\"\"", op
    end

    test "in escapes string members" do
      op = WhereOp.in("lawKey", ["CA-STAT", "x\" or true or \""])
      assert_equal "lawKey in (\"CA-STAT\", \"x\\\" or true or \\\"\")", op
    end

    test "contains with annotations" do
      op_contains_stem = WhereOp.contains("a", "A", annotations: {stem: "false"})
      assert_equal "a contains ({stem: false}\"A\")", op_contains_stem

      op_contains_stem = WhereOp.contains("a", "A", annotations: {stem: "true"})
      assert_equal "a contains ({stem: true}\"A\")", op_contains_stem

      op_contains_stem = WhereOp.contains("a", "A", annotations: {prefix: true})
      assert_equal "a contains ({prefix: true}\"A\")", op_contains_stem

      op_contains_stem = WhereOp.contains("a", "A", annotations: {prefix: true, stem: false})
      assert_equal "a contains ({prefix: true, stem: false}\"A\")", op_contains_stem

      op_contains_stem = WhereOp.contains("a", "A", annotations: {stem: false, prefix: true})
      assert_equal "a contains ({stem: false, prefix: true}\"A\")", op_contains_stem
    end

    test "annotations reject a key or value that isn't YQL instead of writing its to_s" do
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {"stem: false} or true or {x" => true}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {"stem\n" => true}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {1 => true}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {stem: nil}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {stem: Object.new}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {stem: [nil]}) }
      assert_raises(ArgumentError) { WhereOp.contains("a", "A", annotations: {weight: Float::NAN}) }
    end

    test "annotations take Arrays, each element written like a value" do
      op = WhereOp.contains("a", "A", annotations: {weights: [1, 2.5], terms: ["x\"y", :z, true, {n: 1}]})
      assert_equal "a contains ({weights: [1, 2.5], terms: [\"x\\\"y\", \"z\", true, {n: 1}]}\"A\")", op
    end

    test "annotations take dotted keys, Symbol values, and nested Hashes" do
      op = WhereOp.nearest_neighbor("v", "q", annotations: {"hnsw.exploreAdditionalHits" => 100, "targetHits" => 10, "label" => :nn})
      assert_equal "({hnsw.exploreAdditionalHits: 100, targetHits: 10, label: \"nn\"}nearestNeighbor(v, q))", op

      op = WhereOp.contains("a", "A", annotations: {origin: {original: "a\"b", offset: 0, length: 3}})
      assert_equal "a contains ({origin: {original: \"a\\\"b\", offset: 0, length: 3}}\"A\")", op
    end

    test "and or" do
      op_and = WhereOp.and(VespaRuby::WhereOp.contains("title", "madonna"), WhereOp.contains("title", "saint"))
      assert_equal "(title contains \"madonna\" and title contains \"saint\")", op_and

      op_or = WhereOp.or(VespaRuby::WhereOp.contains("title", "madonna"), WhereOp.contains("title", "saint"))
      assert_equal "(title contains \"madonna\" or title contains \"saint\")", op_or
    end

    test "and & or need at least 2 terms" do
      assert_raises(ArgumentError) { WhereOp.and("lonely") }
      assert_raises(ArgumentError) { WhereOp.or("lonely") }
    end

    test "and or with multiple right args" do
      op_and = WhereOp.and(VespaRuby::WhereOp.contains("title", "madonna"), WhereOp.contains("title", "saint"), WhereOp.contains("title", "third"), WhereOp.contains("title", "fourth"))
      assert_equal "(title contains \"madonna\" and title contains \"saint\" and title contains \"third\" and title contains \"fourth\")", op_and

      op_or = WhereOp.or(VespaRuby::WhereOp.contains("title", "madonna"), WhereOp.contains("title", "saint"), WhereOp.contains("title", "third"), WhereOp.contains("title", "fourth"))
      assert_equal "(title contains \"madonna\" or title contains \"saint\" or title contains \"third\" or title contains \"fourth\")", op_or
    end

    test "nearest_neighbor" do
      op_nn = WhereOp.nearest_neighbor("vector_a", "vector_b")
      assert_equal "nearestNeighbor(vector_a, vector_b)", op_nn
    end

    test "wand" do
      op_wand = WhereOp.wand(["description", [[11, 1], [37, 2]]])
      assert_equal "wand(description, [[11, 1], [37, 2]])", op_wand
    end

    test "wand raises ArgumentError with fewer than two arguments" do
      assert_raises(ArgumentError) { WhereOp.wand(["description"]) }
    end

    test "weak_and" do
      op_weak_and = WhereOp.weak_and(VespaRuby::WhereOp.contains("a", "A"), WhereOp.contains("b", "B"))
      assert_equal "weakAnd(a contains \"A\", b contains \"B\")", op_weak_and
    end

    test "weakAnd with annotations" do
      annotations = {scoreThreshold: 0, targetHits: 7}
      op_weak_and = WhereOp.weak_and(WhereOp.contains("a", "A"), WhereOp.contains("b", "B"), annotations: annotations)
      assert_equal "({scoreThreshold: 0, targetHits: 7}weakAnd(a contains \"A\", b contains \"B\"))", op_weak_and
    end

    test "in" do
      op_in = WhereOp.in("integer_field", [10, 20, 30])
      assert_equal "integer_field in (10, 20, 30)", op_in

      op_in_string = WhereOp.in("string_field", %w[germany france norway])
      assert_equal "string_field in (\"germany\", \"france\", \"norway\")", op_in_string
    end

    test "in raises on an empty or missing set" do
      assert_raises(ArgumentError) { WhereOp.in("string_field", []) }
      assert_raises(ArgumentError) { WhereOp.in("string_field", nil) }
    end

    test "in and phrase raise on a nil or nested member instead of writing it as text" do
      assert_raises(ArgumentError) { WhereOp.in("a", ["x", nil]) }
      assert_raises(ArgumentError) { WhereOp.in("a", ["x", ["y"]]) }
      assert_raises(ArgumentError) { WhereOp.phrase(["x", nil]) }
      assert_raises(ArgumentError) { WhereOp.phrase(["x", ["y"]]) }
      assert_raises(ArgumentError) { WhereOp.phrase(nil) }
      assert_raises(ArgumentError) { WhereOp.phrase([]) }
    end

    test "phrase quotes and escapes each term" do
      assert_equal "phrase(\"a\\\"b\", \"1\", \"c\")", WhereOp.phrase(["a\"b", 1, :c])
    end

    test "uri emits Vespa's uri() with an escaped literal" do
      assert_equal "uri(\"https://x.example/a\\\"b\")", WhereOp.uri("https://x.example/a\"b")
    end

    test "eq writes numbers, number strings, parameter references, and booleans" do
      assert_equal "a = 5", WhereOp.eq("a", 5)
      assert_equal "a = 1.5", WhereOp.eq("a", BigDecimal("1.5"))
      assert_equal "a = 20200101", WhereOp.eq("a", "20200101")
      assert_equal "a = 1e5", WhereOp.eq("a", "1e5")
      assert_equal "a = @x", WhereOp.eq("a", "@x")
      assert_equal "a = true", WhereOp.eq("a", true)
      assert_equal "a = false", WhereOp.eq("a", false)
      assert_equal "a = true", WhereOp.eq("a", "true")
      assert_equal "a = false", WhereOp.eq("a", "false")
    end

    # Vespa's = takes only a number or a boolean: `lawKey = "CA-STAT"` is "not an int item expression".
    test "eq rejects strings, Infinity, and numbers that aren't YQL" do
      [Float::NAN, BigDecimal("NaN"), Rational(1, 2), Complex(1, 2), nil, "CA-STAT", :x,
        "x\" or true or \"", "@x or true", Float::INFINITY, "-Infinity"].each do |bad|
        assert_raises(ArgumentError, bad.inspect) { WhereOp.eq("a", bad) }
      end
    end

    test "comparisons accept only numbers" do
      assert_equal "a < 5", WhereOp.lt("a", 5)
      assert_equal "a <= 5", WhereOp.lte("a", 5)
      assert_equal "a > 5", WhereOp.gt("a", 5)
      assert_equal "a >= -1.5", WhereOp.gte("a", "-1.5")
      assert_raises(ArgumentError) { WhereOp.lt("a", "5 or true") }
      assert_raises(ArgumentError) { WhereOp.gt("a", "5\n or true") }
    end

    test "comparisons and range take every YQL number form" do
      assert_equal "a < 1.5", WhereOp.lt("a", BigDecimal("1.5"))
      assert_equal "a < 1.0e+20", WhereOp.lt("a", 1e20)
      assert_equal "a < @max", WhereOp.lt("a", "@max")
      assert_equal "a <= .5", WhereOp.lte("a", ".5")
      assert_equal "a > 1e5", WhereOp.gt("a", "1e5")
      assert_equal "range(a, -1.5e-3, 2E+5)", WhereOp.range("a", "-1.5e-3", "2E+5")
      assert_equal "range(a, 10.5, 1.0e+20)", WhereOp.range("a", BigDecimal("10.5"), 1e20)
    end

    # After < and >, YQL reads Infinity as a field name; range() is where it is a literal.
    test "a comparison with an infinite bound becomes the clause it means" do
      [Float::INFINITY, "Infinity", BigDecimal("Infinity")].each do |inf|
        assert_equal "range(a, -Infinity, Infinity)", WhereOp.lt("a", inf)
        assert_equal "range(a, -Infinity, Infinity)", WhereOp.lte("a", inf)
        assert_equal "false", WhereOp.gt("a", inf)
        assert_equal "false", WhereOp.gte("a", inf)
      end
      [-Float::INFINITY, "-Infinity", BigDecimal("-Infinity")].each do |inf|
        assert_equal "false", WhereOp.lt("a", inf)
        assert_equal "false", WhereOp.lte("a", inf)
        assert_equal "range(a, -Infinity, Infinity)", WhereOp.gt("a", inf)
        assert_equal "range(a, -Infinity, Infinity)", WhereOp.gte("a", inf)
      end
    end

    test "a parameter reference named Infinity stays a parameter reference" do
      assert_equal "a < @Infinity", WhereOp.lt("a", "@Infinity")
      assert_equal "a > @Infinity", WhereOp.gt("a", "@Infinity")
      assert_equal "a = @Infinity", WhereOp.eq("a", "@Infinity")
    end

    # Vespa: "Expected a numerical argument to range but got 'from'".
    test "range rejects a parameter reference" do
      assert_raises(ArgumentError) { WhereOp.range("a", "@from", 10) }
      assert_raises(ArgumentError) { WhereOp.range("a", 0, "@to") }
      refute WhereOp.valid_numeric_or_number_string?("@from")
    end

    test "comparisons and range reject numbers and strings that aren't YQL" do
      [Float::NAN, BigDecimal("NaN"), Rational(1, 2), Complex(1, 2), nil, true, "+5", "5.5.5", "@", "@max or true", "- 5"].each do |bad|
        assert_raises(ArgumentError, bad.inspect) { WhereOp.lt("a", bad) }
        assert_raises(ArgumentError, bad.inspect) { WhereOp.range("a", 0, bad) }
      end
    end

    test "range applies its annotations" do
      assert_equal "({bounds: \"leftOpen\"}range(a, 1, 10))", WhereOp.range("a", 1, 10, annotations: {bounds: "leftOpen"})
    end

    test "rank" do
      op_rank = WhereOp.rank(WhereOp.contains("a", "A"), WhereOp.contains("b", "B"), WhereOp.contains("c", "C"))
      assert_equal "rank(a contains \"A\", b contains \"B\", c contains \"C\")", op_rank
    end

    test "range" do
      op_range = WhereOp.range("integer_field", 10, 20)
      assert_equal "range(integer_field, 10, 20)", op_range
    end

    test "range_with_valid_inputs" do
      assert_equal "range(field, 1, 10)", VespaRuby::WhereOp.range("field", 1, 10)
      assert_equal "range(field, -1.5, 2.5)", VespaRuby::WhereOp.range("field", -1.5, 2.5)
      assert_equal "range(field, -10, 20)", VespaRuby::WhereOp.range("field", "-10", "20")
    end

    test "range_with_infinite_bounds" do
      assert_equal "range(field, -Infinity, 10)", VespaRuby::WhereOp.range("field", "-Infinity", 10)
      assert_equal "range(field, 1, Infinity)", VespaRuby::WhereOp.range("field", 1, "Infinity")
      assert_equal "range(field, -Infinity, Infinity)", VespaRuby::WhereOp.range("field", "-Infinity", "Infinity")
    end

    test "range rejects a bound with a line break (^/$ would match its first line)" do
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", "5\n) or true or range(x, 0", 10) }
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", 1, "Infinity\n") }
    end

    test "range_with_invalid_lower_bound" do
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", "invalid", 10) }
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", nil, 10) }
    end

    test "range_with_invalid_upper_bound" do
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", 1, "invalid") }
      assert_raises(ArgumentError) { VespaRuby::WhereOp.range("field", 1, nil) }
    end
  end
end
