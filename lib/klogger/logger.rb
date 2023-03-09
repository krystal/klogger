# frozen_string_literal: true

require 'logger'
require 'klogger/formatters/json'
require 'klogger/formatters/simple'
require 'klogger/formatters/go'
require 'concurrent/atomic/thread_local_var'

module Klogger
  class Logger < ::Logger

    attr_reader :name
    attr_reader :destinations
    attr_reader :extra

    LEVELS = [:debug, :info, :warn, :error, :fatal].freeze
    FORMATTERS = {
      json: Formatters::JSON,
      simple: Formatters::Simple,
      go: Formatters::Go
    }.freeze

    def initialize(name, destination: $stdout, formatter: :json, highlight: false, extra: {})
      @name = name
      @extra = extra
      @destinations = []
      @groups = Concurrent::ThreadLocalVar.new([])

      super(destination)
      self.formatter = FORMATTERS[formatter].new(highlight: highlight)
    end

    def exception(exception, message = nil, **additional)
      error({ message: message,
              exception: exception.class.name,
              exception_message: exception.message,
              backtrace: exception.backtrace[0, 4].join("\n") }.merge(additional))
    end

    LEVELS.each do |level|
      define_method(level) do |message = nil, progname = nil, **additional, &block|
        add(Logger.const_get(level.to_s.upcase), message, progname, **additional, &block)
      end
    end

    def group(**additional)
      groups << additional
    def group(**tags)
      @groups.value += [tags]
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

    def add(severity, message = nil, progname = nil, **extra, &block)
      return if silenced?

      severity ||= Logger::UNKNOWN
      return if severity < level

      payload = create_payload(severity, message, extra)

      @destinations.each do |destination|
        destination.call(self, payload.dup)
      rescue StandardError => e
        # If something goes wrong in here, we don't want to break the application
        # so we will rescue that and we'll just use standard warn.
        Kernel.warn "Error while sending payload to destination (#{e.class}): #{e.message}"
      end

      super(severity, payload, progname, &block)
    end

    # rubocop:disable Metrics/AbcSize
    def create_payload(severity, message, extra)
      payload = { time: Time.now.to_s, severity: LEVELS[severity]&.to_s, logger: @name }
      payload.merge!(@extra)

      if message.is_a?(Hash)
        payload.merge!(message)
      elsif message
        payload[:message] = message
      end

      payload.merge!(extra)
      payload.delete(:message) if payload[:message].nil?
      payload.compact!

      @groups.value.each { |group| payload.merge!(group) }
      payload
    end
    # rubocop:enable Metrics/AbcSize

  end
end
