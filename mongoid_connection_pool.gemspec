# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid_connection_pool/version'

Gem::Specification.new do |spec|
  spec.name          = "mongoid_connection_pool"
  spec.version       = MongoidConnectionPool::VERSION
  spec.authors       = ["Brian Goff"]
  spec.email         = ["cpuguy83@gmail.com"]
  spec.description   = %q{Provides connection pooling for Mongoid}
  spec.summary       = %q{Provides connection pooling for Mongoid}
  spec.homepage      = "http://www.github.com/cpuguy83/mongoid_connection_pooling"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency "mongoid", "~> 3.1.0"
end
