# frozen_string_literal: true

require_relative 'artifact_helpers'
require_relative 'helpers'
require_relative 'perf_results_evaluator'

module Stoat
  # Perf - for fetching and evaluating performance test results
  class Perf
    include ArtifactHelpers
    include Helpers

    ALLOCS_THRESHOLD = 1.0
    ARTIFACT = 'performance-test-results'
    RESULTS_FILE = 'performance_results.md'
    TIME_THRESHOLD = 3.0

    def go
      puts 'Fetching latest performance test results...'
      fetch_artifact(ARTIFACT, cleanup_routine:)
      file_utils.mv File.join(ARTIFACT, RESULTS_FILE), File.join(Dir.pwd, RESULTS_FILE)
      file_utils.rm_rf ARTIFACT
      puts "Results available at '#{RESULTS_FILE}'"
      report
    end

    private

    def cleanup_routine
      proc do
        bail "Failed to extract '#{RESULTS_FILE}'" unless File.exist?(RESULTS_FILE)

        data = File.read(RESULTS_FILE).split("\n")
        first_md_line_idx = data.find_index { |line| line.start_with?('|') }
        file_utils.rm_f(RESULTS_FILE)
        File.write(RESULTS_FILE, data[first_md_line_idx..].join("\n"))
      end
    end

    def report
      PerfResultsEvaluator.new(RESULTS_FILE).evaluate
    end
  end
end
