# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('./lib', __dir__))
require 'klogger'

def example
  $stdout.print '   '
  yield
end

def print_examples(logger)
  example { logger.info('Hello world!', name: 'Adam') }
  example { logger.debug('Debug message', age: 30, ip_address: 1.234) }
  example { logger.error('This should not happen', number: 4) }
  example { logger.warn('Something bad will happen soon if you are not careful') }

  begin
    1 / 0
  rescue StandardError => e
    example { logger.exception(e, backtrace: nil) }
  end
end

puts
puts <<-'ART'
         _
    /\ /\ | ___   __ _  __ _  ___ _ __
   / //_/ |/ _ \ / _` |/ _` |/ _ \ '__|
  / __ \| | (_) | (_| | (_| |  __/ |
  \/  \/|_|\___/ \__, |\__, |\___|_|
                 |___/ |___/
ART

puts "JSON output\n\n"
logger = Klogger.new('example', formatter: :json, highlight: true)
print_examples(logger)

puts
puts "Simple output\n\n"
logger = Klogger.new('example', formatter: :simple, highlight: true)
print_examples(logger)

puts
puts "Go-style output\n\n"
logger = Klogger.new('example', formatter: :go, highlight: true)
print_examples(logger)

puts
puts
