# frozen_string_literal: true

require 'klogger/formatters/abstract'
require 'klogger/colors'

module Klogger
  module Formatters
    class Go < Abstract

      EXCLUDE_FROM_TAGS = [:time, :severity, :message].freeze

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      def call(_severity, time, _progname, payload)
        string = String.new
        string << time.strftime('%Y-%m-%d %H:%M:%S %z')
        string << ' '
        string << colorize(payload[:severity].ljust(7, ' ').upcase, payload[:severity].to_sym)
        if payload[:message]
          string << colorize(payload[:message], :white)
          string << ' '
        end
        payload.each do |key, value|
          next if EXCLUDE_FROM_TAGS.include?(key)

          string << colorize("#{key}=", :gray)
          string << colorize(sanitize_value(value), :white)
          string << ' '
        end
        string.strip + "\n"
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

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
