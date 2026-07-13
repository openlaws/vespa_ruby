# frozen_string_literal: true

require "test_helper"

module VespaRuby
  class TestQueryHelper < ActiveSupport::TestCase
    class Dummy
      include VespaRuby::QueryHelper
    end

    def setup
      @dummy = Dummy.new
    end

    test "handle_splat" do
      result = @dummy.handle_splat([], default: "*")
      assert_equal "*", result

      result2 = @dummy.handle_splat(%w[true false])
      assert_equal "true, false", result2

      result3 = @dummy.handle_splat(%w[A B])
      assert_equal "\"A\", \"B\"", result3

      result4 = @dummy.handle_splat([1])
      assert_equal "1", result4

      result4 = @dummy.handle_splat([1, 2, 3])
      assert_equal "1, 2, 3", result4
    end

    test "double_quote_string" do
      result = @dummy.double_quoted_string("abc")
      assert_equal "\"abc\"", result
    end

    test "double_quoted_string escapes embedded quotes and backslashes" do
      # A bare " would close the literal and inject YQL; it must be backslash-escaped.
      assert_equal "\"a\\\"b\"", @dummy.double_quoted_string("a\"b")
      # A bare \ starts an escape sequence; it must itself be escaped.
      assert_equal "\"a\\\\b\"", @dummy.double_quoted_string("a\\b")
      # The canonical injection attempt: break out and OR in a new clause.
      assert_equal "\"A\\\" or lawKey contains \\\"B\"",
        @dummy.double_quoted_string("A\" or lawKey contains \"B")
    end

    test "escape_yql_string leaves ordinary values untouched" do
      assert_equal "CA-STAT", @dummy.escape_yql_string("CA-STAT")
      assert_equal "title_15.division_1.chapter_1", @dummy.escape_yql_string("title_15.division_1.chapter_1")
    end

    test "quoted_array escapes each element" do
      assert_equal ["\"a\\\"b\"", "\"c\\\\d\""], @dummy.quoted_array(["a\"b", "c\\d"])
    end

    test "unquoted?" do
      refute @dummy.unquoted?("a")

      assert @dummy.unquoted?(true)
      assert @dummy.unquoted?(false)
      assert @dummy.unquoted?("true")
      assert @dummy.unquoted?("false")
      assert @dummy.unquoted?(1)
      assert @dummy.unquoted?(1.0)
    end
  end
end
