# frozen_string_literal: true

require 'klogger/logger'

module Klogger
  class TaggedLogger

    def initialize(parent, **tags)
      @parent = parent
      @tags = tags
    end

    Klogger::Logger::LEVELS.each do |level|
      define_method(level) do |message = nil, progname = nil, **tags, &block|
        @parent.public_send(level, message, progname, **@tags.merge(tags), &block)
      end
    end

    def exception(exception, message = nil, **tags)
      @parent.exception(exception, message, **@tags.merge(tags))
    end

    def group(**tags, &block)
      @parent.group(**@tags.merge(tags), &block)
    end

    def add_group(**tags)
      @parent.add_group(**@tags.merge(tags))
    end

    def pop_group
      @parent.pop_group
    end

    def tagged(**tags, &block)
      @parent.tagged(**@tags.merge(tags), &block)
    end

    def silence!(&block)
      @parent.silence!(&block)
    end

    def unsilence!(&block)
      @parent.unsilence!(&block)
    end

    def silenced?
      @parent.silenced?
    end

    def create_tagged_logger(**tags)
      @parent.create_tagged_logger(**@tags.merge(tags))
    end

  end
end
