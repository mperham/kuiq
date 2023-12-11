# frozen_string_literal: true

require_relative "lib/kuiq/version"

Gem::Specification.new do |spec|
  spec.name = "kuiq"
  spec.version = Kuiq::VERSION
  spec.authors = ["Mike Perham"]
  spec.email = ["mperham@gmail.com"]

  spec.summary = "Sidekiq desktop application"
  spec.description = "A native desktop application for Sidekiq operators, using the Glimmer toolkit"
  spec.homepage = "https://github.com/mperham/quick"
  spec.license = "LGPL-3.0"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "bin"
  spec.executables = ["kuiq"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  spec.add_dependency "glimmer-dsl-libui", "= 0.11.6"
  spec.add_dependency "sidekiq", "~> 7.2"
end
