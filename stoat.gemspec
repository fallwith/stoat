# frozen_string_literal: true

require_relative 'lib/stoat/version'

Gem::Specification.new do |spec|
  spec.name = 'stoat'
  spec.version = Stoat::VERSION
  spec.authors = ['Tanna McClure', 'Kayla Reopelle', 'James Bunch', 'Hannah Ramadan']
  spec.email = 'support@newrelic.com'
  spec.licenses = %w[Apache-2.0]
  spec.summary = 'Stoat is a little helper to assist with releases'
  spec.homepage = 'https://github.com/newrelic/stoat'
  spec.required_ruby_version = '>= 3.1.0'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/CHANGELOG.md"
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test)/|\.|Gemfile|Rakefile|stoat\.jpg)})
    end
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday-retry', '~> 2.0'
  spec.add_dependency 'octokit', '~> 5.6'
  spec.add_dependency 'rubyzip', '~> 2.3'
  spec.add_dependency 'tty-option', '~> 0.2'

  spec.add_development_dependency 'minitest', '~> 5.16'
  spec.add_development_dependency 'pry', '~> 0.14'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rubocop', '~> 1.36'
  spec.add_development_dependency 'rubocop-minitest', '~> 0.22'
  spec.add_development_dependency 'rubocop-rake', '~> 0.6'
  spec.add_development_dependency 'simplecov', '~> 0.21'
end
