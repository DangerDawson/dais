# coding: utf-8
require File.expand_path('../lib/dais/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'dais'
  spec.version       = Dais::VERSION.dup
  spec.authors       = ['David Dawson']
  spec.email         = ['david.dawson@gmaill.com']
  spec.summary       = ''
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'log_buddy'
  spec.add_development_dependency 'awesome_print'
end
