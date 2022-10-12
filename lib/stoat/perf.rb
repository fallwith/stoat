# frozen_string_literal: true

require 'fileutils'
require 'octokit'
require 'zip'

require_relative 'helpers'
require_relative 'perf_results_evaluator'

module Stoat
  # Perf - for fetching and evaluating performance test results
  class Perf
    include Helpers

    TOKEN_ENV_VAR = 'NR_GITHUB_TOKEN'
    REPO = 'newrelic/newrelic-ruby-agent'
    NAME = 'performance-test-results'
    RESULTS_FILE = 'performance_results.md'
    TIME_THRESHOLD = 3.0
    ALLOCS_THRESHOLD = 1.0

    def go
      fetch_latest
      report
    end

    private

    def access_token
      @access_token ||= begin
        bail "GitHub Access Token env var '#{TOKEN_ENV_VAR}' not set!" unless ENV.key?(TOKEN_ENV_VAR)

        ENV.fetch(TOKEN_ENV_VAR)
      end
    end

    # TODO: error handling
    def artifact_url
      client.repository_artifacts(REPO).artifacts.detect { |a| a.name == NAME }.archive_download_url
    end

    def cleanup_results
      bail "Failed to extract '#{RESULTS_FILE}'" unless File.exist?(RESULTS_FILE)

      data = File.read(RESULTS_FILE).split("\n")
      first_md_line_idx = data.find_index { |line| line.start_with?('|') }
      file_utils.rm_f(RESULTS_FILE)
      File.write(RESULTS_FILE, data[first_md_line_idx..].join("\n"))
    end

    def client
      @client ||= Octokit::Client.new(access_token:)
    end

    def fetch_latest
      puts 'Fetching latest performance test results...'
      data = grab_latest_zip_blob
      write_zip(data)
      unzip_zip
      cleanup_results
      puts "File written to #{RESULTS_FILE}"
    end

    def file_utils
      @file_utils ||= FileUtils
    end

    def grab_latest_zip_blob
      client.get(artifact_url)
    end

    def report
      PerfResultsEvaluator.new(RESULTS_FILE).evaluate
    end

    # TODO: can we not simply unzip the data blob without writing it to disk
    #       first?
    def unzip_zip
      file_utils.rm_f(RESULTS_FILE)
      Zip::File.open(zip_file) { |z| z.first.extract }
      file_utils.rm_f(zip_file)
    end

    def write_zip(data)
      file_utils.rm_f zip_file
      File.write(zip_file, data)
    end

    def zip_file
      @zip_file ||= "#{RESULTS_FILE}.zip"
    end
  end
end
