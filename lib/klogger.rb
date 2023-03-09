# frozen_string_literal: true

require 'klogger/logger'

module Klogger

  def self.new(*args, **kwargs)
    Logger.new(*args, **kwargs)
  end

end
