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
      unquoted?(original) ? original : "\"#{original}\""
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
      original.collect { |v| "\"#{v}\"" }
    end

    # See https://docs.vespa.ai/en/reference/query-language-reference.html#annotations
    #: (Hash[untyped, untyped], String?)
    def build_annotations(hash, phrase = nil)
      pairs = hash.map { |k, v| "#{k}: #{v.is_a?(String) ? double_quoted_string(v) : v}" }

      phrase.present? ? "({#{pairs.join(", ")}}#{phrase})" : "{#{pairs.join(", ")}}"
    end
  end
end
