# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  module QueryHelper
    # A YQL identifier (https://github.com/vespa-engine/vespa/blob/master/container-search/src/main/antlr4/com/yahoo/search/yql/yqlplus.g4).
    IDENTIFIER = /[A-Za-z_][A-Za-z0-9_-]*/
    # An annotation key: an identifier, dotted for a nested one (hnsw.exploreAdditionalHits).
    ANNOTATION_KEY = /\A#{IDENTIFIER}(\.#{IDENTIFIER})*\z/
    # A YQL number literal (its INT and FLOAT tokens: an optional "-", an exponent, and a
    # leading "." are allowed, a leading "+" is not), Infinity, or a request parameter
    # reference (@name).
    NUMBER_STRING = /\A(-?(Infinity|(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?)|@#{IDENTIFIER})\z/
    # A request parameter reference (@name), resolved by Vespa from the request's parameters.
    PARAMETER_REFERENCE = /\A@#{IDENTIFIER}\z/
    # The named escapes a YQL string literal accepts for control characters.
    CONTROL_ESCAPES = {"\b" => "\\b", "\t" => "\\t", "\n" => "\\n", "\f" => "\\f", "\r" => "\\r"}.freeze #: Hash[String, String]

    #: (Array[String], String?)
    def handle_splat(arg_array, default: nil)
      return default if arg_array.empty?

      # Wrap in double quotes
      result = (arg_array.all? { |v| unquoted?(v) }) ? arg_array : arg_array.map { |v| double_quoted_string(v) }

      result.join(", ")
    end

    #: (String) -> String
    def double_quoted_string(original)
      unquoted?(original) ? original : "\"#{escape_yql_string(original)}\""
    end

    # Escape the characters that would otherwise let a value break out of a
    # double-quoted YQL string literal: a bare `"` closes the literal and a bare
    # `\` starts an escape sequence. Without this, an attacker-supplied field
    # value (e.g. a caller passing user input as a `contains` argument) can inject
    # arbitrary YQL. Control characters are written with the escapes YQL accepts
    # (\n, \t, \u0000, …) so a line break or NUL can't produce a parse error.
    #: (String) -> String
    def escape_yql_string(original)
      original.to_s.gsub(/[\\"\x00-\x1f]/) do |char|
        CONTROL_ESCAPES[char] || ((char.ord < 0x20) ? format("\\u%04x", char.ord) : "\\#{char}")
      end
    end

    # A double-quoted, escaped string literal for a scalar value. nil and collections
    # raise instead of writing their to_s into the YQL.
    #: (String|Symbol|Numeric|bool) -> String
    def quoted_value(value)
      unless value.is_a?(String) || value.is_a?(Symbol) || value.is_a?(Numeric) || value == true || value == false
        raise ArgumentError.new("Expected a String, Symbol, Numeric, or boolean value, got #{value.inspect}")
      end

      "\"#{escape_yql_string(value.to_s)}\""
    end

    #: (Numeric|TrueClass|FalseClass|String) -> bool
    def unquoted?(element)
      element.is_a?(Numeric) ||
        element.is_a?(TrueClass) ||
        element.is_a?(FalseClass) ||
        (element.is_a?(String) && %w[true false].include?(element))
    end

    # Each element as a quoted, escaped string literal (see quoted_value: nil and
    # collections raise).
    #: (Array[String|Symbol|Numeric|bool]) -> Array[String]
    def quoted_array(original)
      original.map { |v| quoted_value(v) }
    end

    # The YQL text of a number: an Integer, a Float (not NaN), a BigDecimal (whose to_s,
    # "0.15e1", isn't YQL), or a String holding a number literal, Infinity, or a request
    # parameter reference (@name). Anything else (nil, NaN, Rational, Complex, other text)
    # raises instead of writing its to_s into the YQL. PARAMETER: false raises on a
    # parameter reference too, for operators that take only a literal (range()).
    #: (untyped, ?String, ?parameter: bool) -> String
    def number_literal(value, description = "number", parameter: true)
      text =
        case value
        when Integer then value.to_s
        when Float then value.to_s unless value.nan?
        when String then value if NUMBER_STRING.match?(value)
        else
          value.to_s("F") if defined?(::BigDecimal) && value.is_a?(::BigDecimal) && !value.nan?
        end
      raise ArgumentError.new("Invalid #{description}: expected a number, got #{value.inspect}") unless text
      if !parameter && PARAMETER_REFERENCE.match?(text)
        raise ArgumentError.new("Invalid #{description}: expected a number literal, got the parameter reference #{value.inspect}")
      end

      text
    end

    # See https://docs.vespa.ai/en/reference/query-language-reference.html#annotations
    # Keys must be YQL identifiers (dotted allowed). Values are numbers, booleans,
    # Strings and Symbols (quoted and escaped), nested Hashes, or Arrays of those;
    # anything else raises instead of writing its to_s into the YQL.
    #: (Hash[untyped, untyped], String?) -> String
    def build_annotations(hash, phrase = nil)
      pairs = hash.map { |k, v| "#{annotation_key(k)}: #{annotation_value(v)}" }

      phrase.present? ? "({#{pairs.join(", ")}}#{phrase})" : "{#{pairs.join(", ")}}"
    end

    #: (untyped) -> String
    def annotation_key(key)
      valid = (key.is_a?(Symbol) || key.is_a?(String)) && ANNOTATION_KEY.match?(key.to_s)
      raise ArgumentError.new("Invalid annotation key: expected a YQL identifier, got #{key.inspect}") unless valid

      key.to_s
    end

    #: (untyped) -> String
    def annotation_value(value)
      case value
      when true, false then value.to_s
      when String then double_quoted_string(value)
      when Symbol then quoted_value(value)
      when Numeric then number_literal(value, "annotation value")
      when Hash then build_annotations(value)
      when Array then "[#{value.map { |v| annotation_value(v) }.join(", ")}]"
      else raise ArgumentError.new("Invalid annotation value: expected a number, boolean, String, Symbol, Hash, or Array, got #{value.inspect}")
      end
    end
  end
end
