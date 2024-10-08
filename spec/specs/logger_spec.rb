# frozen_string_literal: true

require 'spec_helper'
require 'klogger'
require 'klogger/logger'
require_relative '../helpers/fake_destination'

module Klogger

  RSpec.describe Logger do
    before { Timecop.freeze }
    after { Timecop.return }

    let!(:output) { StringIO.new }

    context 'with a non-highlighting JSON logger with a name' do
      subject(:logger) { described_class.new('example', destination: output, formatter: :json) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'logs a message' do
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', message: 'Hello, world!' }.to_json + "\n")
          end

          it 'logs structured data' do
            logger.public_send(severity, foo: 'bar')
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', foo: 'bar' }.to_json + "\n")
          end

          it 'logs a message and structured data' do
            logger.public_send(severity, 'Hello world', foo: 'bar')
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', message: 'Hello world',
                                          foo: 'bar' }.to_json + "\n")
          end

          it 'logs the result of a block as a message' do
            logger.public_send(severity) { 'Hello world!' }
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', message: 'Hello world!' }.to_json + "\n")
          end

          it 'logs the result of a block as a message combined with an provided message' do
            logger.public_send(severity, 'Test') { 'Hello world!' }
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', message: 'Test: Hello world!' }.to_json + "\n")
          end

          it 'logs the result of a block as a message combined with an provided message and tags' do
            logger.public_send(severity, 'Test', abc: 'def') { 'Hello world!' }
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', message: 'Test: Hello world!',
                                          abc: 'def' }.to_json + "\n")
          end

          it 'includes any tags included for the logger before the message' do
            logger = described_class.new('example', destination: output, formatter: :json, tags: { foo: 'bar' })
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          logger: 'example', foo: 'bar', message: 'Hello, world!' }.to_json + "\n")
          end

          it 'includes tags specified on the instance group after the message' do
            logger.group(foo: 'bar') do
              logger.public_send(severity, 'Hello, world!')
              expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                            logger: 'example', message: 'Hello, world!', foo: 'bar' }.to_json + "\n")
            end
          end

          it 'includes tags specified on the instance group along with other structured data' do
            logger.group(foo: 'bar') do
              logger.public_send(severity, baz: 'qux')
              expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                            logger: 'example', baz: 'qux', foo: 'bar' }.to_json + "\n")
            end
          end

          it 'ensures thread safety with groups' do
            thread = Thread.start do
              logger.group(set_in_thread: '123') do
                logger.public_send(severity, 'Hello!')
                expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                              logger: 'example',
                                              message: 'Hello!', set_in_thread: '123' }.to_json + "\n")

                # keep the thread alive until we kill it later
                sleep 1
              end
            end
            sleep 0.1
            logger.group(foo: 'bar') do
              output.truncate(0)
              output.rewind
              logger.public_send(severity, 'Hello!')
              expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                            logger: 'example',
                                            message: 'Hello!', foo: 'bar' }.to_json + "\n")
            end
          ensure
            thread.kill
          end

          it 'includes nested group attributes' do
            logger.group(level1: 'a') do
              logger.group(level2: 'b') do
                logger.public_send(severity, 'Hello')
                expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                              logger: 'example', message: 'Hello',
                                              level1: 'a', level2: 'b' }.to_json + "\n")
              end
            end
          end

          it 'includes group ids in the output if configured' do
            logger = described_class.new('example', destination: output, include_group_ids: true, formatter: :json)
            logger.group do
              logger.group do
                logger.public_send(severity, 'Hello')
              end
            end
            parsed_json = JSON.parse(output.string)
            expect(parsed_json['groups']).to match(/\A[a-f0-9]{8},[a-f0-9]{8}\z/)
          end

          it 'ensures that nested group attributes are not present once the group has been called' do
            logger.group(level1: 'a') do
              logger.group(level2: 'b') do
                logger.public_send(severity, 'Hello')
                expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                              logger: 'example', message: 'Hello',
                                              level1: 'a', level2: 'b' }.to_json + "\n")
              end
              output.truncate(0)
              output.rewind
              logger.group(level3: 'c') do
                logger.public_send(severity, 'Hello')
                expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                              logger: 'example', message: 'Hello',
                                              level1: 'a', level3: 'c' }.to_json + "\n")
              end
            end
          end

          it 'includes global group ids in the output if configured' do
            Klogger.group(foo: 'bar') do
              logger.public_send(severity, 'Hello')
              expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                            logger: 'example',
                                            message: 'Hello',
                                            foo: 'bar' }.to_json + "\n")
            end
          end

          it 'can combine local and global group tags with global ones first' do
            logger.group(fruit: 'apple') do
              Klogger.group(foo: 'bar') do
                logger.public_send(severity, 'Hello')
                expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                              logger: 'example',
                                              message: 'Hello',
                                              foo: 'bar', fruit: 'apple' }.to_json + "\n")
              end
            end
          end

          it 'adds global group data into any logger' do
            output2 = StringIO.new
            another_logger = described_class.new('another', destination: output2, formatter: :json)
            Klogger.group(foo: 'bar') do
              logger.public_send(severity, 'Hello')
              another_logger.public_send(severity, 'Hello')

              expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                            logger: 'example',
                                            message: 'Hello',
                                            foo: 'bar' }.to_json + "\n")

              expect(output2.string).to eq({ time: Time.now.to_s, severity: severity,
                                             logger: 'another',
                                             message: 'Hello',
                                             foo: 'bar' }.to_json + "\n")
            end
          end

          it 'logs nothing if silenced' do
            logger.silence!
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to be_empty
          end
        end
      end

      describe '#silence!' do
        it 'silences the logger' do
          logger.silence!
          expect(logger.silenced?).to be true
        end

        it 'silences the logger for the duration of the block' do
          logger.silence! do
            expect(logger.silenced?).to be true
          end
          expect(logger.silenced?).to be false
        end
      end

      describe '#unsilence!' do
        it 'unsilences the logger' do
          logger.silence!
          expect(logger.silenced?).to be true
          logger.unsilence!
          expect(logger.silenced?).to be false
        end

        it 'unsilences the logger for the duration of the block' do
          logger.silence!
          logger.unsilence! do
            expect(logger.silenced?).to be false
          end
          expect(logger.silenced?).to be true
        end
      end

      describe '#exception' do
        it 'logs the exception details' do
          1 / 0
        rescue StandardError => e
          logger.exception(e)
          expect(output.string).to eq({ time: Time.now.to_s, severity: 'error',
                                        logger: 'example',
                                        exception: 'ZeroDivisionError',
                                        exception_message: 'divided by 0',
                                        backtrace: e.backtrace[0, 4].join("\n") }.to_json + "\n")
        end

        it 'logs the exception details and a message' do
          1 / 0
        rescue StandardError => e
          logger.exception(e, "Oops - that's silly")
          expect(output.string).to eq({ time: Time.now.to_s, severity: 'error',
                                        logger: 'example',
                                        message: "Oops - that's silly",
                                        exception: 'ZeroDivisionError',
                                        exception_message: 'divided by 0',
                                        backtrace: e.backtrace[0, 4].join("\n") }.to_json + "\n")
        end

        it 'logs the exception details and structured data' do
          1 / 0
        rescue StandardError => e
          logger.exception(e, "Oops - that's silly", foo: 'bar')
          expect(output.string).to eq({ time: Time.now.to_s, severity: 'error',
                                        logger: 'example',
                                        message: "Oops - that's silly",
                                        exception: 'ZeroDivisionError',
                                        exception_message: 'divided by 0',
                                        backtrace: e.backtrace[0, 4].join("\n"),
                                        foo: 'bar' }.to_json + "\n")
        end
      end
    end

    context 'with a highlighting logger' do
      subject(:logger) { described_class.new('example', destination: output, formatter: :json, highlight: true) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'logs a message' do
            expect(JSONHighlighter).to receive(:highlight).and_return('formatted-json')
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq("formatted-json\n")
          end
        end

        # .. no additional tests added here because they're covered above.
      end
    end

    context 'with simple formatter with no highlighting' do
      subject(:logger) { described_class.new('example', destination: output, formatter: :simple) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'logs a message in the correct format' do
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq(
              "time: #{Time.now} severity: #{severity} logger: example message: Hello, world!\n"
            )
          end
        end

        # .. no additional tests added here because they're covered above.
      end
    end

    context 'with go formatter with no highlighting' do
      subject(:logger) { described_class.new('example', destination: output, formatter: :go) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'logs a message in the correct format' do
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq(
              "#{Time.now} #{severity.to_s.upcase.ljust(6, ' ')} Hello, world! logger=example\n"
            )
          end
        end

        # .. no additional tests added here because they're covered above.
      end
    end

    context 'without a name' do
      subject(:logger) { described_class.new(destination: output, formatter: :json) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'logs a message' do
            logger.public_send(severity, 'Hello, world!')
            expect(output.string).to eq({ time: Time.now.to_s, severity: severity,
                                          message: 'Hello, world!' }.to_json + "\n")
          end
        end

        # .. no additional tests added here because they're covered above.
      end
    end

    context 'with a destination' do
      subject(:logger) { described_class.new('example', destination: output) }

      [:info, :debug, :warn, :error, :fatal].each do |severity|
        describe "##{severity}" do
          it 'calls the destination when logging' do
            called = false
            destination = proc do |logger, payload, group_ids|
              called = true
              expect(logger).to eq logger
              expect(payload[:message]).to eq 'Hello, world!'
              expect(payload[:severity]).to eq severity.to_s
              expect(group_ids).to eq []
            end
            logger.add_destination(destination)
            logger.public_send(severity, 'Hello, world!')
            expect(called).to be true
          end

          it 'includes any group ids that were generated seperately' do
            called = false
            destination = proc do |_logger, _payload, group_ids|
              called = true
              expect(group_ids).to match [match(/\A[a-f0-9]{8}/), match(/\A[a-f0-9]{8}/)]
            end
            logger.add_destination(destination)
            logger.group do
              logger.group do
                logger.public_send(severity, 'Hello, world!')
              end
            end
            expect(called).to be true
          end
        end
      end
    end

    describe '#create_tagged_logger' do
      subject(:logger) { described_class.new('example', destination: output, formatter: :json) }

      it 'returns a new tagged logger' do
        expect(logger.create_tagged_logger(tag: 'tag1')).to be_a Klogger::TaggedLogger
      end
    end

    describe '#add_destination' do
      subject(:logger) { described_class.new('example', destination: output) }

      it 'adds the destination' do
        destination = proc {}
        logger.add_destination(destination)
        expect(logger.destinations).to include destination
      end
    end

    describe '#remove_destination' do
      subject(:logger) { described_class.new('example', destination: output) }

      it 'removes the destination' do
        destination = proc {}
        logger.add_destination(destination)
        logger.remove_destination(destination)
        expect(logger.destinations).to_not include destination
      end
    end

    describe '#with_destination' do
      subject(:logger) { described_class.new('example', destination: output) }
      let(:fake_destination) { FakeDestination.new }

      it 'sends log output to the given destination for the duration of the block' do
        logger.info 'line1'
        logger.with_destination(fake_destination) do
          logger.info 'line2'
          logger.info 'line3'
        end
        logger.info 'line4'
        expect(fake_destination.lines).to match [
          [logger, hash_including(message: 'line2'), []],
          [logger, hash_including(message: 'line3'), []]
        ]
      end
    end
  end

end
# rubocop:enable Style/StringConcatenation
