# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/env/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-env"
  spec.version       = Capistrano::Env::VERSION
  spec.authors       = ["Eduardo Gutierrez"]
  spec.email         = ["eduardo@vermonster.com"]
  spec.description   = %q{ Set and unset ENV variables in your .env file using S3 as a storage backend. }
  spec.summary       = %q{ Capistrano tasks to manage and deploy .env files stored on S3. }
  spec.homepage      = "https://github.com/ecbypi/capistrano-env"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'aws-sdk', '~> 1.15'
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
