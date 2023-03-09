![Screenshot](https://share.adam.ac/23/Screen-Shot-2023-03-09-16-00-57.65-DWjwl4M5Gu.png)

<p align="center">
  <a href="https://rubygems.org/gems/klogger-logger">
    <img src="https://img.shields.io/gem/v/klogger-logger.svg?label=rubygems&logo=rubygems&color=%23E9573F" alt="RubyGems">
  </a>
  <a href="https://github.com/krystal/klogger/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/krystal/klogger/commit.yml?branch=main&logo=github" alt="Actions Status">
  </a>
  <a href="https://github.com/krystal/klogger/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/krystal/klogger.svg?style=flat" alt="License Status">
  </a>
</p>

Klogger is an opinionated logger for Ruby applications to allow consistent and structured logging.

- Output can be sent to STDOUT or a file. The logger is backed by the standard Ruby `Logger` class.
- Ouput can be presented in various formats.
- Output can be highlighted with appropriate colours based on severity (optional).
- Additional destinations can easily be added for shipping log data to other services.

## Installation

Add the gem to your Gemfile.

```ruby
gem "klogger-logger", '~> 1.0'
```

## Usage

This shows some typical usage of the logger along with example output. The `Klogger::Logger` instance will output to STDOUT by default but

```ruby
# Initialize a new logger instance and provide a name for it
logger = Klogger.new('api-requests')

# Initialize a new logger and log to a file
logger = Klogger.new('api-requests', destination: 'log/api-requests.log')

# Initialize a new logger with simple formatting
logger = Klogger.new('api-requests', formatter: :simple)

# Disable coloured output (likely desired for production use)
logger = Klogger.new('api-requests', color: false)

# Log a simple message to the logger
logger.info("Received API request from 1.2.3.4 for /api/v1/users") # => {"time":"2023-03-09 11:56:37 +0000","severity":"info","logger":"example","message":"Received API request from 1.2.3.4 for /api/v1/users"}

# Log structured data
logger.info(method: 'GET', ip_address: '1.2.3.4', path: '/api/v1/users') # => {"time":"2023-03-09 11:56:57 +0000","severity":"info","logger":"example","method":"GET","ip_address":"1.2.3.4","path":"/api/v1/users"}

# Handling exceptions
begin
  1/0
rescue => e
  # Just log the exception
  logger.exception(e) # => {"time":"2023-03-09 11:57:55 +0000","severity":"error","logger":"example","exception":"ZeroDivisionError","exception_message":"divided by 0","backtrace":"(irb):6:in `/'\n(irb):6:in `<top (required)>'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `eval'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `evaluate'"}

  # Log with a message
  logger.exception(e, "Something went wrong") # => {"time":"2023-03-09 11:57:55 +0000","severity":"error","logger":"example","message":"Something went wrong","exception":"ZeroDivisionError","exception_message":"divided by 0","backtrace":"(irb):6:in `/'\n(irb):6:in `<top (required)>'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `eval'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `evaluate'"}

  # Log with structured data
  logger.exception(e, input: 130) # => {"time":"2023-03-09 11:57:55 +0000","severity":"error","logger":"example","exception":"ZeroDivisionError","exception_message":"divided by 0","backtrace":"(irb):6:in `/'\n(irb):6:in `<top (required)>'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `eval'\n/Users/adam/.rbenv/versions/3.0.3/lib/ruby/gems/3.0.0/gems/irb-1.4.2/lib/irb/workspace.rb:119:in `evaluate'","input":130}
end

# Log with groups with additional structured data provided
logger.group(ip_address: '1.2.3.4') do
  logger.info("This is a message") # => {"time":"2023-03-09 11:59:01 +0000","severity":"info","logger":"example","message":"This is a message","ip_address":"1.2.3.4"}
  logger.info(method: 'GET') # => {"time":"2023-03-09 11:59:01 +0000","severity":"info","logger":"example","method":"GET","ip_address":"1.2.3.4"}
end

# Silece all log output
logger.silence! do
  # All calls to log something will be ignored within this block
end
```

## Sending log data elsewhere

In many cases you won't want to keep your log data on a local disk or within STDOUT. You can use this additional option to have data dispatched automatically to other services which you decide upon.

```ruby
# This is just an example class. You can create whatever class you want here and it'll be called
# with the call method.
class GraylogDestination < Klogger::Destination

  def initialize(host, port)
    @notifier = GELF::Notifier.new(host, port)
  end

  def call(logger, payload)
    @notifer.notify!(facility: "my-app", **payload.delete)
  end

end

# Create a logger and add the destination
logger = Klogger.new('workers', destination: $stdout)
logger.add_destination(GraylogDestination.new('graylog.example.com', 12201))
```
