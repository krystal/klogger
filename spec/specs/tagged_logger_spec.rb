# frozen_string_literal: true

require 'spec_helper'
require 'klogger'
require 'klogger/tagged_logger'

module Klogger

  RSpec.describe TaggedLogger do
    before { Timecop.freeze }
    after { Timecop.return }

    let!(:output) { StringIO.new }
    let(:logger) { Logger.new('example', destination: output, formatter: :json) }

    subject(:tagged_logger) { described_class.new(logger, tag1: 'test') }

    Logger::LEVELS.each do |level|
      describe "##{level}" do
        it 'logs with the parent classes' do
          tagged_logger.public_send(level, 'Hello', tag2: 'test')
          expect(output.string).to eq({ time: Time.now.to_s, severity: level,
                                        logger: 'example', message: 'Hello',
                                        tag1: 'test', tag2: 'test' }.to_json + "\n")
        end
      end
    end

    describe '#group' do
      it 'logs appropriately' do
        tagged_logger.group(grouptag: 'gt1') do
          tagged_logger.info 'Hello', tag2: 'test'
        end
        expect(output.string).to eq({ time: Time.now.to_s, severity: 'info',
                                      logger: 'example', message: 'Hello',
                                      tag1: 'test', tag2: 'test', grouptag: 'gt1' }.to_json + "\n")
      end
    end

    describe '#tagged' do
      it 'logs appropriately' do
        tagged_logger.tagged(taggedtag: 'gt1') do
          tagged_logger.info 'Hello', tag2: 'test'
        end
        expect(output.string).to eq({ time: Time.now.to_s, severity: 'info',
                                      logger: 'example', message: 'Hello',
                                      tag1: 'test', tag2: 'test', taggedtag: 'gt1' }.to_json + "\n")
      end
    end
  end

end
