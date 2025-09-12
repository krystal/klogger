# frozen_string_literal: true

require 'coderay'
require 'klogger/colors'

# This class is responsible for receiving log data and sending it to an underlying
module Klogger
  class JSONHighlighter

    class << self

      def highlight(output)
        severity = ::Regexp.last_match(1).to_sym if output.match(/"severity":"(\w+)"/)

        # Determine the color based on severity
        case severity
        when :info
          color = :info
        when :warn
          color = :warn
        when :error, :fatal
          color = :error
        else # default (debug, unknown, or no severity)
          color = :white
        end

        # Apply color to the entire JSON output
        Colors.colorize(output, color)
      end

    end

  end
end
