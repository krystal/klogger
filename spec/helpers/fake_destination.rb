# frozen_string_literal: true

class FakeDestination

  attr_reader :lines

  def initialize
    @lines = []
  end

  def call(logger, payload, group_ids)
    @lines << [logger, payload, group_ids]
  end

end
