# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  # Implements operations here: https://docs.vespa.ai/en/reference/query-language-reference.html#where
  module WhereOp
    extend QueryHelper

    # The value is always a quoted, escaped string literal: Vespa rejects a bare
    # number or boolean after contains ("Cannot cast java.lang.Integer to
    # java.lang.String") and matches "5" and "true" against int and bool fields.
    #: (String, String|Symbol|Numeric|bool, Hash[untyped, untyped]) -> String
    def self.contains(left, right, annotations: {})
      right_value = quoted_value(right)
      right_value = build_annotations(annotations, right_value) unless annotations.empty?
      "#{left} contains #{right_value}"
    end

    #: (String, String) -> String
    def self.and(*terms)
      raise ArgumentError.new("and() requires at least two terms") unless terms.length >= 2

      "(#{terms.join(" and ")})"
    end

    #: (String, String) -> String
    def self.or(*terms)
      raise ArgumentError.new("or() requires at least two terms") unless terms.length >= 2

      "(#{terms.join(" or ")})"
    end

    # The arguments are YQL (field names, query inputs, clauses), written as given:
    # never pass request input.
    #: (String, String, Hash[untyped, untyped]) -> String
    def self.nearest_neighbor(doc_vector, query_vector, annotations: {})
      phrase = "nearestNeighbor(#{doc_vector}, #{query_vector})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    # The arguments are YQL (field names, query inputs, clauses), written as given:
    # never pass request input.
    #: (Array[untyped], Hash[untyped, untyped]) -> String
    def self.wand(arguments, annotations: {})
      raise ArgumentError.new("wand requires at least two arguments") unless arguments.is_a?(Array) && arguments.length > 1

      # map(&:to_s) is required, not redundant: arguments may hold nested arrays (e.g. a
      # weighted set like [[11, 1], [37, 2]]), and bare Array#join would recursively join
      # those with the same separator ("11, 1, 37, 2") instead of stringifying them whole.
      # rubocop:disable Style/MapJoin
      phrase = "wand(#{arguments.map(&:to_s).join(", ")})"
      # rubocop:enable Style/MapJoin

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    # The arguments are YQL (field names, query inputs, clauses), written as given:
    # never pass request input.
    #: (String, String, Hash[untyped, untyped]) -> String
    def self.weak_and(left, right, annotations: {})
      phrase = "weakAnd(#{left}, #{right})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    # Split apart match and ranking arguments for usability. The arguments are YQL
    # clauses, written as given: never pass request input.
    def self.rank(match_argument, *ranking_arguments)
      return "rank(#{match_argument})" if ranking_arguments.empty?

      "rank(#{match_argument}, #{ranking_arguments.join(", ")})"
    end

    # input is a YQL expression, written as given: never pass request input (send it
    # as a request parameter and pass "@name").
    #: (String) -> String
    def self.user_input(input)
      "userInput(#{input})"
    end

    # TODO: Consider implementing more optimal parameter substitution
    # where integer_field in (@integer_values)&integer_values=10,20,30
    # where string_field in (@string_values)&string_values=germany,france,norway
    #: (String, Array[String|Symbol|Numeric|bool]) -> String
    def self.in(value, set)
      # in () is a YQL syntax error.
      raise ArgumentError.new("in() requires an Array of at least one value") unless set.is_a?(Array) && !set.empty?

      # Do not wrap Integers in quotes
      return "#{value} in (#{set.join(", ")})" if set.all? { |v| v.is_a?(Integer) }

      # Every other member is a quoted, escaped string literal; nil and collections raise.
      "#{value} in (#{quoted_array(set).join(", ")})"
    end

    #: (String) -> String
    def self.not(clause)
      "!(#{clause})"
    end

    # range() lower and upper bounds are inclusive. "-Infinity" and "Infinity" are valid values.
    # Each bound is a number, a number string, or a request parameter reference ("@name");
    # see QueryHelper#number_literal.
    #: (String, String|Numeric, String|Numeric, Hash[untyped, untyped]) -> String
    def self.range(field, lower_bound, upper_bound, annotations: {})
      phrase = "range(#{field}, #{number_literal(lower_bound, "range lower bound")}, #{number_literal(upper_bound, "range upper bound")})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    # Whether NUMBER is something range and the comparisons write; see
    # QueryHelper#number_literal.
    #: (untyped) -> bool
    def self.valid_numeric_or_number_string?(number)
      number_literal(number)
      true
    rescue ArgumentError
      false
    end

    # Every term is a quoted, escaped string literal; nil and collections raise.
    #: (Array[String|Symbol|Numeric|bool]) -> String
    def self.phrase(term_array)
      raise ArgumentError.new("phrase() requires an Array of at least one term") unless term_array.is_a?(Array) && !term_array.empty?

      "phrase(#{quoted_array(term_array).join(", ")})"
    end

    # Vespa's operator is uri(); url( is a YQL syntax error.
    #: (String) -> String
    def self.uri(uri)
      "uri(#{quoted_value(uri)})"
    end

    # TODO: Not great support below since its difficult to figure out field names from strings

    # The right side of lt/lte/gt/gte is a number, a number string, or a request
    # parameter reference ("@name"); see QueryHelper#number_literal.
    #: (String|Numeric, String|Numeric) -> String
    def self.lt(left, right)
      comparison(left, "<", right)
    end

    #: (String|Numeric, String|Numeric) -> String
    def self.lte(left, right)
      comparison(left, "<=", right)
    end

    #: (String|Numeric, String|Numeric) -> String
    def self.gt(left, right)
      comparison(left, ">", right)
    end

    #: (String|Numeric, String|Numeric) -> String
    def self.gte(left, right)
      comparison(left, ">=", right)
    end

    #: (String|Numeric, String, String|Numeric) -> String
    def self.comparison(left, operator, right)
      "#{left} #{operator} #{number_literal(right, "#{operator} value")}"
    end
    private_class_method :comparison

    # String value must go on the right. We can't tell the difference between field names and values.
    # A number is written by QueryHelper#number_literal (NaN, Rational, and Complex raise),
    # a boolean bare, and anything else as a quoted, escaped string literal.
    #: (String, String|Symbol|Numeric|bool) -> String
    def self.eq(left, right)
      return "#{left} = #{number_literal(right, "eq value")}" if right.is_a?(Numeric)
      return "#{left} = #{right}" if right == true || right == false

      "#{left} = #{quoted_value(right)}"
    end
  end
end
