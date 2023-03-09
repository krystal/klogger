# frozen_string_literal: true

require 'json'
require 'klogger/formatters/abstract'
require 'klogger/json_highlighter'

module Klogger
  module Formatters
    class JSON < Abstract

      def call(_severity, _time, _progname, payload)
        json = payload.to_json
        if @highlight
          json.gsub!('","', '", "')
          json.gsub!(/\A{/, '{ ')
          json.gsub!(/\}\z/, ' }')
          json = JSONHighlighter.highlight(json)
        end
        json + "\n"
      end

    end
  end
end
