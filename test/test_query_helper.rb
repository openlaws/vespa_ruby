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
