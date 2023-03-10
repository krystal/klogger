# frozen_string_literal: true

require 'logger'
require 'securerandom'
require 'klogger/formatters/json'
require 'klogger/formatters/simple'
require 'klogger/formatters/go'
require 'concurrent/atomic/thread_local_var'

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

    def initialize(name, destination: $stdout, formatter: :json, highlight: false, include_group_ids: false, tags: {})
      @name = name
      @tags = tags
      @destinations = []
      @groups = Concurrent::ThreadLocalVar.new { [] }
      @include_group_ids = include_group_ids

      super(destination)
      self.formatter = FORMATTERS[formatter].new(highlight: highlight)
    end

    def exception(exception, message = nil, **tags)
      error({ message: message,
              exception: exception.class.name,
              exception_message: exception.message,
              backtrace: exception.backtrace[0, 4].join("\n") }.merge(tags))
    end

    LEVELS.each do |level|
      define_method(level) do |message = nil, progname = nil, **tags, &block|
        add(Logger.const_get(level.to_s.upcase), message, progname, **tags, &block)
      end
    end

    def group(**tags)
      @groups.value += [{ id: SecureRandom.hex(4), tags: tags }]
      yield
    ensure
      @groups.value.pop
    end

    def silence!
      @silence = true
      yield if block_given?
    ensure
      unsilence! if block_given?
    end

    def unsilence!
      @silence = false
      yield if block_given?
    ensure
      silence! if block_given?
    end

    def silenced?
      @silence == true
    end

    def add_destination(destination)
      @destinations << destination
    end

    def remove_destination(destination)
      @destinations.delete(destination)
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

    # rubocop:disable Metrics/AbcSize
    def create_payload(severity, message, tags)
      payload = { time: Time.now.to_s, severity: LEVELS[severity]&.to_s, logger: @name }
      payload.merge!(@tags)

      if message.is_a?(Hash)
        payload.merge!(message)
      elsif message
        payload[:message] = message
      end

      payload.merge!(tags)
      payload.delete(:message) if payload[:message].nil?
      payload.compact!

      group_ids = []
      @groups.value.each do |group|
        payload.merge!(group[:tags])
        group_ids << group[:id]
      end

      payload[:groups] = group_ids.join(',') if @include_group_ids

      [payload, group_ids]
    end
    # rubocop:enable Metrics/AbcSize

    def call_destinations(payload, group_ids)
      @destinations.each do |destination|
        destination.call(self, payload.dup, group_ids)
      rescue StandardError => e
        # If something goes wrong in here, we don't want to break the application
        # so we will rescue that and we'll just use standard warn.
        Kernel.warn "Error while sending payload to destination (#{e.class}): #{e.message}"
      end
    end

  end
end
