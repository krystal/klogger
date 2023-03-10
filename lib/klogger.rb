# frozen_string_literal: true

require 'klogger/logger'

module Klogger

  def self.new(*args, **kwargs)
    Logger.new(*args, **kwargs)
  end

  def self.global_groups
    @global_groups ||= GroupSet.new
  end

  def self.group(**tags, &block)
    global_groups.call(**tags, &block)
  end

  def self.tagged(**tags, &block)
    global_groups.call_without_id(**tags, &block)
  end

end
