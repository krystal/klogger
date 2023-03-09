# frozen_string_literal: true

require File.expand_path('lib/klogger/version', __dir__)

# rubocop:disable Gemspec/RequireMFA
Gem::Specification.new do |s|
  s.name          = 'klogger-logger'
  s.description   = 'A simple Ruby logger'
  s.summary       = s.description
  s.required_ruby_version = '>= 2.6'
  s.homepage      = 'https://github.com/krystal/klogger'
  s.version       = Klogger::VERSION
  s.files         = Dir.glob('{lib}/**/*')
  s.require_paths = ['lib']
  s.authors       = ['Adam Cooke']
  s.email         = ['adam@krystal.uk']
  s.licenses      = ['MIT']
  s.add_runtime_dependency('json')
  s.add_runtime_dependency('rouge', '>= 3.30', '< 5.0')
end
# rubocop:enable Gemspec/RequireMFA
