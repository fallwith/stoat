# frozen_string_literal: true

require 'test_helper'

# TestCoverage - test lib/stoat/coverage.rb
class TestCoverage < Minitest::Test
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/BlockLength
  def test_go
    opwd = Dir.pwd
    Dir.mktmpdir do |dir|
      Dir.chdir dir
      stoat = Stoat::Coverage.new
      def stoat.puts(_txt); end

      def stoat.exec(_cmd)
        'execed'
      end

      github_mock = MiniTest::Mock.new
      stoat.instance_variable_set(:@github_mock, github_mock)
      artifact_mock = MiniTest::Mock.new
      artifact_mock.expect :name, Stoat::Coverage::ARTIFACT
      fake_url = 'rupert://davies'
      artifact_mock.expect :archive_download_url, fake_url
      repository_artifacts_mock = MiniTest::Mock.new
      repository_artifacts_mock.expect :nil?, false
      repository_artifacts_mock.expect :artifacts, [artifact_mock]
      repository_artifacts_mock.expect :artifacts, [artifact_mock]
      github_mock.expect :repository_artifacts, repository_artifacts_mock do |repo, page:|
        assert_equal Stoat::Helpers::REPO, repo
        assert_equal 1, page
      end
      github_mock.expect :get, nil, [fake_url]

      def stoat.github
        @github_mock
      end

      extractable = []
      def extractable.extract; end

      Zip::File.stub :open, nil, [extractable] do
        stoat.go
      end

      github_mock.verify
      artifact_mock.verify
      repository_artifacts_mock.verify
    end
  ensure
    Dir.chdir opwd
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/BlockLength
end
