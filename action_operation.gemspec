#!/usr/bin/env ruby

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "action_operation/version"

Gem::Specification.new do |spec|
  spec.name = "action_operation"
  spec.version = ActionOperation::VERSION
  spec.authors = ["Kurtis Rainbolt-Greene"]
  spec.email = ["kurtis@rainbolt-greene.online"]
  spec.summary = %q{A set of BPMN style operation logic}
  spec.description = spec.summary
  spec.homepage = "http://krainboltgreene.github.io/action_operation"
  spec.license = "ISC"

  spec.files = Dir[File.join("lib", "**", "*"), "LICENSE", "README.md", "Rakefile"]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rake", "~> 12.2"
  spec.add_development_dependency "pry", "~> 0.11"
  spec.add_development_dependency "pry-doc", "~> 0.11"
  spec.add_runtime_dependency "activesupport", ">= 4.0.0", ">= 4.1", ">= 5.0.0", ">= 5.1"
  spec.add_runtime_dependency "smart_params", ">= 2.0"
end
