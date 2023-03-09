# frozen_string_literal: true

require 'klogger/formatters/abstract'

module Klogger
  module Formatters
    class Simple < Abstract

      def call(_severity, _time, _progname, payload)
        string = String.new
        payload.each do |key, value|
          string << ' ' if string.length.positive?
          string << "#{colorize(key.to_s + ':', payload[:severity].to_sym)} #{sanitize_value(value)}"
        end
        string + "\n"
      end

      private

      def colorize(text, color)
        return text unless @highlight

        Colors.colorize(text, color)
      end

      def sanitize_value(value)
        value.to_s.gsub("\n", '\\\\n')
      end

    end
  end
end
