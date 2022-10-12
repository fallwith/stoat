# frozen_string_literal: true

require 'test_helper'

# TestPerf - test lib/perf.rb
class TestPerf < Minitest::Test
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def test_go
    token = 'Is Pluto a planet?'
    url = 'Bathtub stunt racer'
    blob = 'Gobo'
    markdown = 'Ralphie from New York'

    perf = Stoat::Perf.new

    def perf.file_utils
      utils = MiniTest::Mock.new
      utils.expect :rm_f, nil, [String]
    end

    def perf.puts(txt); end

    filename = Stoat::Perf::RESULTS_FILE
    filename_zip = "#{Stoat::Perf::RESULTS_FILE}.zip"

    zip_file = MiniTest::Mock.new
    zip_file.expect :extract, nil

    artifact = MiniTest::Mock.new
    artifact.expect :name, Stoat::Perf::NAME
    artifact.expect :archive_download_url, url
    artifacts = [artifact]

    repository_artifacts = MiniTest::Mock.new
    repository_artifacts.expect :artifacts, artifacts

    zip_file = MiniTest::Mock.new
    zip_open = proc do |fname|
      assert_equal filename_zip, fname
      [zip_file]
    end

    evaluator = MiniTest::Mock.new
    evaluator.expect :evaluate, nil

    octo = MiniTest::Mock.new
    octo.expect :get, blob, [url]
    octo.expect :repository_artifacts, repository_artifacts, [Stoat::Perf::REPO]

    ENV.stub :key?, true, [Stoat::Perf::TOKEN_ENV_VAR] do
      ENV.stub :fetch, token, [Stoat::Perf::TOKEN_ENV_VAR] do
        Octokit::Client.stub :new, octo do
          File.stub :write, nil, [filename_zip, blob] do
            Zip::File.stub :open, zip_open, [filename_zip] do
              File.stub :exist?, true, [filename] do
                File.stub :read, md_data(markdown), [filename] do
                  Stoat::PerfResultsEvaluator.stub :new, evaluator, [filename] do
                    perf.go
                  end
                end
              end
            end
          end
        end
      end
    end

    zip_file.verify
    artifact.verify
    repository_artifacts.verify
    zip_file.verify
    evaluator.verify
    octo.verify
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def test_cleanup_results
    markdown = '| Li Hing Mui'
    filename = Stoat::Perf::RESULTS_FILE
    perf = Stoat::Perf.new

    File.stub :exist?, true, [filename] do
      File.stub :read, md_data(markdown), [filename] do
        File.stub :write, nil, [filename, markdown] do
          perf.send :cleanup_results
        end
      end
    end
  end

  def test_cleanup_results_but_results_are_absent
    perf = Stoat::Perf.new

    def perf.warn(msg); end

    File.stub :exist?, false, [Stoat::Perf::RESULTS_FILE] do
      assert_raises(SystemExit) { perf.send :cleanup_results }
    end
  end

  def test_access_token_is_not_set_in_env
    perf = Stoat::Perf.new

    def perf.warn(msg); end

    ENV.stub :key?, false, [Stoat::Perf::TOKEN_ENV_VAR] do
      assert_raises(SystemExit) { perf.send :access_token }
    end
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
