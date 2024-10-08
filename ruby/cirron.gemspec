
# frozen_string_literal: true

require 'fileutils'
require 'pathname'

Gem::Specification.new do |spec|
  spec.name = "cirron"
  spec.version = "0.4.0"
  spec.authors = ["Matt Stuchlik"]
  spec.email = ["matej.stuchlik@gmail.com"]

  spec.summary = "Cirron measures how many CPU instructions and system calls a piece of Ruby code executes."
  spec.description = File.read(File.join(File.dirname(__FILE__), "README.md"))
  spec.homepage = "https://github.com/s7nfo/Cirron"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/s7nfo/Cirron"

  spec.files = [
    "lib/apple_arm_events.h",
    "lib/cirron.rb",
    "lib/cirronlib.cpp",
    "lib/collector.rb",
    "lib/tracer.rb",
    "lib/injector.rb",
    "README.md",
    "LICENSE",
    "cirron.gemspec"
  ]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
