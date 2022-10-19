# frozen_string_literal: true

require 'fileutils'
require 'test_helper'
require 'tmpdir'

# TestGemfile - test lib/gemfile.rb
# rubocop:disable Metrics/ClassLength
class TestGemfile < Minitest::Test
  def test_go
    Dir.mktmpdir do |dir|
      write_original_files(dir)
      stoat = fresh_gemfile(dir)
      stoat.instance_variable_set(:@latest_release, fake_release)
      stoat.go
      verify_modifications(dir)
    end
  end

  def test_latest_release
    stoat = fresh_gemfile(nil)
    def stoat.github
      mock = MiniTest::Mock.new

      # rubocop:disable Style/OpenStructUse
      r = OpenStruct.new(data: OpenStruct.new(repository: OpenStruct.new(releases: OpenStruct.new(nodes: %w[node]))))
      # rubocop:enable Style/OpenStructUse
      mock.expect :post, r, ['/graphql', String]
      mock
    end
    stoat.send(:latest_release)
  end

  def test_latest_release_fetch_fails
    stoat = fresh_gemfile(nil)
    def stoat.warn(msg)
      instance_variable_get(:@test_class).assert_match 'kaboom', msg
    end

    def stoat.github
      raise 'Earth shattering kaboom'
    end
    assert_raises(SystemExit) { stoat.send(:latest_release) }
  end

  def test_read_files_when_a_file_is_absent
    Dir.mktmpdir do |dir|
      stoat = fresh_gemfile(dir)
      def stoat.warn(msg)
        instance_variable_get(:@test_class).assert_match(/^No '\w+' file/, msg)
      end
      assert_raises(SystemExit) { stoat.send(:read_files) }
    end
  end

  def test_release_query
    stoat = fresh_gemfile(nil)
    query = stoat.send(:release_query)
    query_element_two = query.split("\n")[1]
    assert_match(/owner: "([^"]+)", name: "([^"]+)"/, query_element_two)
    query_element_two =~ /owner: "([^"]+)", name: "([^"]+)"/
    repo = [Regexp.last_match(1), Regexp.last_match(2)].join('/')
    assert_equal Stoat::Helpers::REPO, repo
  end

  def test_verify_file_changes
    stoat = fresh_gemfile(nil)
    file = 'Bingdao'

    def stoat.warn(msg)
      instance_variable_get(:@test_class).assert_match(/^Failed to modify/, msg)
    end

    content = 'Same old'
    stoat.instance_variable_set(:@data, { original: { file => content }, modified: { file => content } })
    assert_raises(SystemExit) { stoat.send(:verify_file_changes, file) }
  end

  # helpers

  def fake_release
    Struct.new('FakeCommit', :oid)
    commit = Struct::FakeCommit.new(latest_sha)
    Struct.new('FakeRelease', :tagCommit, :name)
    Struct::FakeRelease.new(commit, latest_version)
  end

  def fresh_gemfile(path)
    s = Stoat::Gemfile.new(path)
    s.instance_variable_set(:@test_class, self)
    s
  end

  def gemfile_content(gem_version)
    <<~GEMFILE
      # frozen_string_literal: true

      source 'https://rubygems.org'

      gem 'awesome_print'
      gem 'interactive_editor'
      gem 'neovim'

      gem 'newrelic_rpm', git: 'https://github.com/newrelic/newrelic-ruby-agent.git', tag: '#{gem_version}'
      gem 'newrelic-infinite_tracing', git: 'https://github.com/newrelic/newrelic-ruby-agent.git', tag: '#{gem_version}'

      gem 'pry'
      gem 'rubocop'
      gem 'vimgolf'
    GEMFILE
  end

  def latest_sha
    'eb538f5df3198027e1049d318083000a'
  end

  def latest_version
    '1.1.3.8'
  end

  def lockfile_content(gem_version, sha)
    <<~GEMFILE_LOCK
      GIT
        remote: https://github.com/jberkel/interactive_editor.git
        revision: f32bf2b129716070df6a45c516df3bffb0272a9d
        tag: v0.0.11
        specs:
          interactive_editor (0.0.11)

      GIT
        remote: https://github.com/newrelic/newrelic-ruby-agent.git
        revision: #{sha}
        tag: #{gem_version}
        specs:
          newrelic-infinite_tracing (#{gem_version})
            grpc (~> 1.34)
            newrelic_rpm (= #{gem_version})
          newrelic_rpm (#{gem_version})

      GIT
        remote: https://github.com/pry/pry.git
        revision: v0aae8c94ad03a732659ed56dcd5088469a15eebf
        tag: v0.14.1
        specs:
          pry (0.14.1)

      PLATFORMS
        arm64-darwin
        arm64-darwin-20
        arm64-darwin-21
        ruby
        x86_64-darwin
        x86_64-darwin-18
        x86_64-darwin-19
        x86_64-darwin-20
        x86_64-darwin-21
        x86_64-linux

      DEPENDENCIES
        interactive_editor!
        newrelic_rpm!
        pry!
    GEMFILE_LOCK
  end

  def original_sha
    '105ecfe9f555344c13d5e337c65dfa41'
  end

  def original_version
    '0.0.7'
  end

  def papers_content(gem_version)
    <<~PAPERS
      #
      # http://github.com/newrelic/papers
      ---
      gems:
        scientist-1.6.3:
          license: MIT
          license_url: https://github.com/github/scientist/blob/main/LICENSE.txt
          project_url: https://github.com/github/scientist
        newrelic_rpm-#{gem_version}:
          license: Apache 2.0
          license_url: http://www.apache.org/licenses/
          project_url: https://github.com/newrelic/newrelic-ruby-agent
        grpc-1.48.0:
            license: Apache 2.0
            license_url: https://github.com/grpc/grpc/blob/master/LICENSE
            project_url: https://github.com/grpc/grpc
        newrelic-infinite_tracing-#{gem_version}:
            license: New Relic
            license_url: https://github.com/newrelic/newrelic-ruby-agent
            project_url: https://github.com/newrelic/newrelic-ruby-agent
    PAPERS
  end

  def prep_subdirectories(dir)
    [Stoat::GemfileHelpers::GEMFILE, Stoat::GemfileHelpers::LOCKFILE, Stoat::GemfileHelpers::PAPERSFILE].each do |path|
      FileUtils.mkdir_p File.join(dir, File.dirname(path))
    end
  end

  def verify_modifications(dir)
    modified_gemfile = File.read(File.join(dir, Stoat::GemfileHelpers::GEMFILE))
    assert_equal gemfile_content(latest_version), modified_gemfile

    modified_lockfile = File.read(File.join(dir, Stoat::GemfileHelpers::LOCKFILE))
    assert_equal lockfile_content(latest_version, latest_sha), modified_lockfile

    modified_papersfile = File.read(File.join(dir, Stoat::GemfileHelpers::PAPERSFILE))
    assert_equal papers_content(latest_version), modified_papersfile
  end

  def write_original_files(dir)
    prep_subdirectories(dir)
    File.write(File.join(dir, Stoat::GemfileHelpers::GEMFILE), gemfile_content(original_version))
    File.write(File.join(dir, Stoat::GemfileHelpers::LOCKFILE), lockfile_content(original_version, original_sha))
    File.write(File.join(dir, Stoat::GemfileHelpers::PAPERSFILE), papers_content(original_version))
  end
end
# rubocop:enable Metrics/ClassLength
