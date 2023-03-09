# frozen_string_literal: true

module Klogger
  module Colors

    COLORS = {
      info: 75,
      warn: 220,
      debug: 252,
      error: 203,
      fatal: 203,
      white: 255,
      gray: 243
    }.freeze

    class << self

      def colorize(text, color)
        color = COLORS[color]
        "\e[38;5;#{color}m#{text}\e[0m"
      end

    end

  end
end
