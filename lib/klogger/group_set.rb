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
      add(_id: false, **tags)
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

    def add(_id: true, **tags)
      id = _id ? SecureRandom.hex(4) : nil
      @groups.value += [{ id: id, tags: tags }]
      id
    end

    def pop
      @groups.value.pop
    end

  end
end
