# frozen_string_literal: true

require 'concurrent/atomic/thread_local_var'

module Klogger
  class GroupSet

    def initialize
      @groups = Concurrent::ThreadLocalVar.new { [] }
    end

    def groups
      @groups.value
    end

    def call(**tags)
      add(**tags)
      yield
    ensure
      pop
    end

    def add(**tags)
      id = SecureRandom.hex(4)
      @groups.value += [{ id: id, tags: tags }]
      id
    end

    def pop
      @groups.value.pop
    end

  end
end
