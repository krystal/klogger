![Screenshot](https://share.adam.ac/23/Screen-Shot-2023-03-09-16-00-57.65-DWjwl4M5Gu.png)

<p align="center">
  <a href="https://rubygems.org/gems/klogger-logger">
    <img src="https://img.shields.io/gem/v/klogger-logger?label=RubyGems&logo=rubygems" alt="RubyGems">
  </a>
  <a href="https://github.com/krystal/klogger/actions">
    <img src="https://img.shields.io/github/actions/workflow/status/krystal/klogger/commit.yaml?branch=main&logo=github" alt="Actions Status">
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
gem "klogger-logger", '~> 1.1'
```

## Usage

This shows some typical usage of the logger along with example output. The `Klogger::Logger` instance will output to STDOUT by default but can be redirectly.

### Setting up a logger

To begin, you need an instance of your logger. Loggers are thread-safe so you can use a single instance across multiple classes and requests. There are a few options that you can control about a logger. These are documented below.

```ruby
# The most basic logger includes a name and nothing else. This will log to STDOUT and use
# the default formatter without colouring.
Klogger.new(name)

# You can customise where log output goes using the destination argument. You can provide a device
# that response to write & close or a path to a file. The same as Ruby's logger class.
Klogger.new(name, destination: $stderr)
Klogger.new(name, destination: 'log/events.log')
Klogger.new(name, destination: StringIO.new)

# To customise the formatting of the log output, you can provide a formatter.
Klogger.new(name, formatter: :json)
Klogger.new(name, formatter: :simple)
Klogger.new(name, formatter: :go)

# You can also enable colouring/highlighting.
Klogger.new(name, highlight: true)
Klogger.new(name, highlight: Rails.env.development?)

# You can add tags to be included in all log lines for this logger.
Klogger.new(name, tags: { app: 'example-app' })
```

### Logging

When you want to log something, you have the option of 5 severities (`debug`, `info`, `warn`, `error` and `fatal`). For this example, we'll use `info` but it is interchangable with any of the other severities.

```ruby
# The most basic way to log is to provide a message.
logger.info("Hello world!")

# To add additional tags to the line, you can do so by passing a hash.
logger.info("Sending e-mail", recipient: "adam@example.com", subject: "Hello world!")

# The message is optional and you can just pass a hash too
logger.info(ip_address: "1.2.3.4", method: "POST", path: "/login")

# Blocks can also be passed to the logger to log the result of that block
logger.info { "Hello world!" }
logger.info('Result of 1 + 1') { 1 + 1 } # Logs with a message of "Result: 2"
```

### Loggging exceptions

Exceptions happen and when they do, you want to know about them. Klogger provides a helper method to log exceptions. These will automatically be logged with the `error` severity.

```ruby
begin
  # Do somethign bad
rescue => e
  # Just log the exception
  logger.exception(e)

  # You can also provide a message
  logger.exception(e, "Something went wrong")

  # You can also provide a hash of additional tags
  logger.exception(e, "Something went wrong", tags: { user_id: 123 })
end
```

### Groups

Groups allow you to group related log entries together. They do two things:

1. They allow you to add tags to all logs which are within the group
2. They assign a random ID to the group which is included with all logs within the group

Here's an example of how they work.

```ruby
# In this example, both log entries within the block will be tagged with the `url` tag from the group.
logger.group(url: "https://example.com/my-files.zip") do # 92b1b62c
  logger.info("Download starting")
  file = download_file('...')
  logger.info("Download complete", size: file.size)
end
```

You'll notice in that example the comment `92b1b62c`. This is the group ID for this block. This is a random ID which is generated when the group is created. It is included with all logs within the group thus allowing you to search for that reference to find all logs related to that group. If groups are nested, you'll have multiple IDs. By default, these group IDs are not shown in your output.

```ruby
# If you wish for group IDs to be included in your output, you can enable that in the logger
Klogger.new(name, include_group_ids: true)
```

### Silencing

Sometimes you don't want to log for a little while. You can use the `silence` method to temporarily disable logging.

```ruby
# Calling this will silence the logs until you unsilence again
logger.silence!
logger.unsilence!

# Alternative, you can use the block option which will unsilence when complete.
logger.silence! do
  # Logs will be silenced here
end
```

### Sending log data elsewhere

In many cases you won't want to keep your log data on a local disk or within STDOUT. You can use this additional option to have data dispatched automatically to other services which you decide upon.

```ruby
# This is just an example class. You can create whatever class you want here and it'll be called
# with the call method.
class GraylogDestination

  def initialize(host, port)
    @notifier = GELF::Notifier.new(host, port)
  end

  def call(logger, payload, group_ids)
    message = payload.delete(:message)
    @notifer.notify!(facility: "my-app", short_message: message, group_ids: group_ids, **payload)
  end

end

# Create a logger and add the destination
logger = Klogger.new(name)
logger.add_destination(GraylogDestination.new('graylog.example.com', 12201))
```
