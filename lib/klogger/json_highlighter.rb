# frozen_string_literal: true

require 'rouge'

# This class is responsible for receiving log data and sending it to an underlying
module Klogger
  class JSONHighlighter

    class Theme < Rouge::CSSTheme

      style Text, fg: '#ffffff'
      style Literal::String,
            Literal::Number, fg: '#35AEFF'
      style Punctuation, fg: '#888888'

    end

    class ErrorTheme < Theme

      style Literal::String,
            Literal::Number, fg: '#FF355D'

    end

    class WarnTheme < Theme

      style Literal::String,
            Literal::Number, fg: '#FFD700'

    end

    class DebugTheme < Theme

      style Text, fg: '#999999'
      style Literal::String,
            Literal::Number, fg: '#cccccc'

    end

    LEXER = Rouge::Lexers::JSON.new
    FORMATTER = Rouge::Formatters::Terminal256
    FORMATTERS = {
      info: FORMATTER.new(Theme.new),
      debug: FORMATTER.new(DebugTheme.new),
      warn: FORMATTER.new(WarnTheme.new),
      error: FORMATTER.new(ErrorTheme.new),
      fatal: FORMATTER.new(ErrorTheme.new)
    }.freeze

    class << self

      def highlight(output)
        severity = ::Regexp.last_match(1).to_sym if output.match(/"severity":"(\w+)"/)
        formatter = FORMATTERS[severity] || FORMATTERS[:info]
        formatter.format(LEXER.lex(output))
      end

    end

  end
end
