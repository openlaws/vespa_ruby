# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  # Implements operations here: https://docs.vespa.ai/en/reference/query-language-reference.html#where
  module WhereOp
    extend QueryHelper

    #: (String, untyped, Hash[untyped, untyped]) -> String
    def self.contains(left, right, annotations: {})
      return "#{left} contains ({stem: #{annotations[:stem]}}#{right})" if annotations[:stem]&.equal?("false")
      return "#{left} contains #{double_quoted_string(right)}" if right.is_a?(String)

      "#{left} contains #{right}"
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

    #: (String, String, Hash[untyped, untyped]) -> String
    def self.nearest_neighbor(doc_vector, query_vector, annotations: {})
      phrase = "nearestNeighbor(#{doc_vector}, #{query_vector})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    #: (Array[untyped], Hash[untyped, untyped]) -> String
    def self.wand(arguments, annotations: {})
      raise ArgumentError("wand requires at least two arguments") unless arguments.is_a?(Array) && arguments.length > 1

      phrase = "wand(#{arguments.map(&:to_s).join(", ")})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    #: (String, String, Hash[untyped, untyped]) -> String
    def self.weak_and(left, right, annotations: {})
      phrase = "weakAnd(#{left}, #{right})"

      annotations.empty? ? phrase : build_annotations(annotations, phrase)
    end

    # Split apart match and ranking arguments for usability
    def self.rank(match_argument, *ranking_arguments)
      return "rank(#{match_argument})" if ranking_arguments.empty?

      "rank(#{match_argument}, #{ranking_arguments.join(", ")})"
    end

    #: (String) -> String
    def self.user_input(input)
      "userInput(#{input})"
    end

    # TODO: Consider implementing more optimal parameter substitution
    # where integer_field in (@integer_values)&integer_values=10,20,30
    # where string_field in (@string_values)&string_values=germany,france,norway
    #: (String, Array[String|Integer]) -> String
    def self.in(value, set)
      # Do not wrap Integers in quotes
      return "#{value} in (#{set.join(", ")})" if set.all? { |v| v.is_a?(Integer) }

      # Wrap strings in double-quotes
      "#{value} in (#{quoted_array(set).join(", ")})"
    end

    #: (String) -> String
    def self.not(clause)
      "!(#{clause})"
    end

    # range() lower and upper bounds are inclusive. "-Infinity" and "Infinity" are valid values.
    #: (String, String|Numeric, String|Numeric, Hash[untyped, untyped]) -> String
    def self.range(field, lower_bound, upper_bound, annotations: {})
      raise ArgumentError.new("Invalid range lower bound") unless valid_numeric_or_number_string?(lower_bound)
      raise ArgumentError.new("Invalid range upper bound") unless valid_numeric_or_number_string?(upper_bound)

      "range(#{field}, #{lower_bound}, #{upper_bound})"
    end

    #: (String|Numeric) -> bool
    def self.valid_numeric_or_number_string?(number)
      number.is_a?(Numeric) || (number.is_a?(String) && /^-?(Infinity|\d+(\.\d+)?)$/.match?(number))
    end

    #: (Array[String]) -> String
    def self.phrase(term_array)
      "phrase(#{quoted_array(term_array).join(", ")})"
    end

    #: (String) -> String
    def self.uri(uri)
      "url(\"#{uri}\")"
    end

    # TODO: Not great support below since its difficult to figure out field names from strings

    #: (String|Numeric, Numeric) -> String
    def self.lt(left, right)
      "#{left} < #{right}"
    end

    #: (String|Numeric, Numeric) -> String
    def self.lte(left, right)
      "#{left} <= #{right}"
    end

    #: (String|Numeric, Numeric) -> String
    def self.gt(left, right)
      "#{left} > #{right}"
    end

    #: (String|Numeric, Numeric) -> String
    def self.gte(left, right)
      "#{left} >= #{right}"
    end

    # String value must go on the right. We can't tell the difference between field names and values.
    #: (String, String|Numeric) -> String
    def self.eq(left, right)
      return "#{left} = \"#{right}\"" if right.is_a?(String)

      "#{left} = #{right}"
    end
  end
end
