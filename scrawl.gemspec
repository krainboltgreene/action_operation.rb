# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "scrawl/version"

Gem::Specification.new do |spec|
  spec.name          = "scrawl"
  spec.version       = Scrawl::VERSION
  spec.authors       = ["Kurtis Rainbolt-Greene"]
  spec.email         = ["me@kurtisrainboltgreene.name"]
  spec.summary       = %q{Turn hashes into simple log-ready output}
  spec.description   = spec.summary
  spec.homepage      = "http://krainboltgreene.github.io/scrawl"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"]
  spec.executables   = Dir["bin/**/*"].map! { |f| f.gsub(/bin\//, "") }
  spec.test_files    = Dir["test/**/*", "spec/**/*"]
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "yard", "~> 0.8"
  spec.add_development_dependency "kramdown", "~> 1.2"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "codeclimate-test-reporter", "~> 0.3"
  spec.add_development_dependency "rubocop", "~> 0.15"
  spec.add_development_dependency "benchmark-ips", "~> 1.2"
  spec.add_development_dependency "ruby-prof", "~> 0.14"
end
