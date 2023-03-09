# frozen_string_literal: true

module Klogger
  class Abstract

    def initialize(highlight: false)
      @highlight = highlight
    end

    def call(_severity, _time, _progname, _payload)
      'no formatter'
    end

  end
end
