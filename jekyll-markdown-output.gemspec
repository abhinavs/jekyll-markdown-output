# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jekyll-markdown-output/version"

Gem::Specification.new do |spec|
  spec.name          = "jekyll-markdown-output"
  spec.version       = Jekyll::MarkdownOutput::VERSION
  spec.authors       = ["Abhinav Saxena"]
  spec.email         = ["abhinav061@gmail.com"]

  spec.summary       = "Emit a Markdown sibling for every Jekyll post or note, for agents and LLMs."
  spec.description   = <<~DESC
    A Jekyll generator that writes a .md file alongside each rendered HTML page,
    so AI agents and crawlers can fetch clean Markdown (with a small machine-
    friendly frontmatter block) instead of parsing HTML. Configurable per
    collection.
  DESC
  spec.homepage      = "https://github.com/abhinavs/jekyll-markdown-output"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata = {
    "homepage_uri"          => spec.homepage,
    "source_code_uri"       => "#{spec.homepage}/tree/main",
    "bug_tracker_uri"       => "#{spec.homepage}/issues",
    "changelog_uri"         => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "rubygems_mfa_required" => "true",
  }

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "jekyll", ">= 3.7", "< 5.0"

  spec.add_development_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.12"
end
