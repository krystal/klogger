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

    def call_without_id(**tags)
      add_without_id(**tags)
      yield
    ensure
      pop
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

    def add_without_id(**tags)
      @groups.value += [{ tags: tags }]
      nil
    end

    def pop
      @groups.value.pop
    end

  end
end
