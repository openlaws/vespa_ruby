# frozen_string_literal: true

# rbs_inline: enabled

module VespaRuby
  module QueryHelper
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
    # arbitrary YQL. Backslash-prefix both in a single pass over the original.
    #: (String) -> String
    def escape_yql_string(original)
      original.to_s.gsub(/[\\"]/) { |char| "\\#{char}" }
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

    #: (Array[String]) -> Array[String]
    def quoted_array(original)
      original.collect { |v| "\"#{escape_yql_string(v)}\"" }
    end

    # See https://docs.vespa.ai/en/reference/query-language-reference.html#annotations
    #: (Hash[untyped, untyped], String?)
    def build_annotations(hash, phrase = nil)
      pairs = hash.map { |k, v| "#{k}: #{v.is_a?(String) ? double_quoted_string(v) : v}" }

      phrase.present? ? "({#{pairs.join(", ")}}#{phrase})" : "{#{pairs.join(", ")}}"
    end
  end
end
