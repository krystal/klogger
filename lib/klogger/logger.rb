# frozen_string_literal: true

require 'logger'
require 'securerandom'

require 'concurrent/atomic/thread_local_var'

require 'klogger/formatters/json'
require 'klogger/formatters/simple'
require 'klogger/formatters/go'
require 'klogger/group_set'
require 'klogger/version'

module Klogger
  class Logger < ::Logger

    attr_reader :name
    attr_reader :destinations
    attr_reader :tags

    LEVELS = [:debug, :info, :warn, :error, :fatal].freeze
    FORMATTERS = {
      json: Formatters::JSON,
      simple: Formatters::Simple,
      go: Formatters::Go
    }.freeze

    def initialize(name = nil,
                   destination: $stdout,
                   formatter: :go,
                   highlight: false,
                   include_group_ids: false,
                   tags: {})
      @name = name
      @tags = tags
      @destinations = []
      @group_set = GroupSet.new
      @silenced = Concurrent::ThreadLocalVar.new { false }
      @block_destinations = Concurrent::ThreadLocalVar.new { [] }
      @include_group_ids = include_group_ids
      super(destination)
      self.formatter = FORMATTERS[formatter].new(highlight: highlight)
    end

    def exception(exception, message = nil, **tags)
      error(
        message: message,
        exception: exception.class.name,
        exception_message: exception.message,
        backtrace: exception.backtrace[0, 4].join("\n"), **tags
      )
    end

    LEVELS.each do |level|
      define_method(level) do |message = nil, progname = nil, **tags, &block|
        add(Logger.const_get(level.to_s.upcase), message, progname, **tags, &block)
      end
    end

    def group(**tags, &block)
      @group_set.call(**tags, &block)
    end

    def add_group(**tags)
      @group_set.add(**tags)
    end

    def pop_group
      @group_set.pop
    end

    def tagged(**tags, &block)
      @group_set.call_without_id(**tags, &block)
    end

    def silence!
      @silenced.value = true
      yield if block_given?
    ensure
      unsilence! if block_given?
    end

    def unsilence!
      @silenced.value = false
      yield if block_given?
    ensure
      silence! if block_given?
    end

    def silenced?
      @silenced.value == true
    end

    def add_destination(destination)
      @destinations << destination
    end

    def remove_destination(destination)
      @destinations.delete(destination)
    end

    def with_destination(destination)
      @block_destinations.value << destination
      yield
    ensure
      @block_destinations.value.delete(destination)
    end

    def create_tagged_logger(**tags)
      TaggedLogger.new(self, **tags)
    end

    private

    def add(severity, message = nil, progname = nil, **tags, &block)
      return if silenced?

      severity ||= Logger::UNKNOWN
      return if severity < level

      if message && block_given?
        message = "#{message}: #{block.call}"
      elsif block_given?
        message = block.call
      end

      payload, group_ids = create_payload(severity, message, tags)
      call_destinations(payload, group_ids)
      super(severity, payload, progname, &block)
    end

    def create_payload(severity, message, tags)
      payload = { time: Time.now.to_s, severity: LEVELS[severity]&.to_s }
      payload[:logger] = @name if @name
      payload.merge!(@tags)

      if message.is_a?(Hash)
        payload.merge!(message)
      elsif message
        payload[:message] = message
      end

      payload.merge!(tags)
      payload.delete(:message) if payload[:message].nil?
      payload.compact!

      group_ids = add_groups_to_payload(payload)

      [payload, group_ids]
    end

    def call_destinations(payload, group_ids)
      (@destinations + @block_destinations.value).each do |destination|
        destination.call(self, payload.dup, group_ids)
      rescue StandardError => e
        # If something goes wrong in here, we don't want to break the application
        # so we will rescue that and we'll just use standard warn.
        Kernel.warn "Error while sending payload to destination (#{e.class}): #{e.message}"
      end
    end

    def add_groups_to_payload(payload)
      group_ids = []

      [Klogger.global_groups, @group_set].each do |group_set|
        group_set.groups.each do |group|
          payload.merge!(group[:tags])
          group_ids << group[:id] if group[:id]
        end
      end

      payload[:groups] = group_ids.join(',') if @include_group_ids
      group_ids
    end

  end
end
