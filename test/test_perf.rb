# frozen_string_literal: true

require 'test_helper'

# TestPerf - test lib/perf.rb
class TestPerf < Minitest::Test
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/BlockLength
  def test_go
    opwd = Dir.pwd
    Dir.mktmpdir do |dir|
      Dir.chdir dir
      stoat = Stoat::Perf.new
      def stoat.puts(_txt); end
      github_mock = MiniTest::Mock.new
      stoat.instance_variable_set(:@github_mock, github_mock)
      artifact_mock = MiniTest::Mock.new
      artifact_mock.expect :name, Stoat::Perf::ARTIFACT
      fake_url = 'toyota://2000gt'
      artifact_mock.expect :archive_download_url, fake_url
      repository_artifacts_mock = MiniTest::Mock.new
      repository_artifacts_mock.expect :artifacts, [artifact_mock]
      github_mock.expect :repository_artifacts, repository_artifacts_mock, [Stoat::Helpers::REPO]
      fake_blob = 'BMT 216A'
      github_mock.expect :get, fake_blob, [fake_url]

      def stoat.github
        @github_mock
      end

      markdown = '| Li Hing Mui'
      unclean_data = md_data(markdown)
      extractable = []
      extractable.instance_variable_set(:@unclean_data, unclean_data)

      def extractable.extract
        File.write(Stoat::Perf::RESULTS_FILE, instance_variable_get(:@unclean_data))
      end

      evaluator_mock = MiniTest::Mock.new
      evaluator_mock.expect :evaluate, nil

      Zip::File.stub :open, nil, [extractable] do
        Stoat::PerfResultsEvaluator.stub :new, evaluator_mock, [Stoat::Perf::RESULTS_FILE] do
          stoat.go
          assert_equal markdown, File.read(Stoat::Perf::RESULTS_FILE)
        end
      end

      github_mock.verify
      artifact_mock.verify
      repository_artifacts_mock.verify
      evaluator_mock.verify
    end
  ensure
    Dir.chdir opwd
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/BlockLength

  def test_cleanup_routine_when_markdown_file_is_absent
    stoat = Stoat::Perf.new
    def stoat.warn(_msg); end
    assert_raises(SystemExit) { stoat.send(:cleanup_routine).call }
  end

  # helpers

  def md_data(markdown)
    <<~MD_DATA
      junk
      non-md
      #{markdown}
    MD_DATA
  end
end
