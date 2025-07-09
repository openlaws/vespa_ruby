require "test_helper"

module VespaRuby
  class TestWhereOp < ActiveSupport::TestCase
    test "contains" do
      op_contains = WhereOp.contains("a", "A")
      assert_equal "a contains \"A\"", op_contains

      op_contains_num = WhereOp.contains("a", 1)
      assert_equal "a contains 1", op_contains_num
    end

    # NOTE: no test for annotated non-String values as there are no valid use cases yet. It looks like the intention was
    # for numeric values, but the interface can also be used with custom objects that implement their own to_s. As a
    # side note, functions could also be on the right side. I think it would make sense in that case to implement as a
    # generic Vespa function class w/ custom to_s or maybe custom classes per function type. That should still be fully
    # compatible w/ the current interface.
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
