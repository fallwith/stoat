# frozen_string_literal: true

require 'test_helper'

# TestPerfResultsEvaluator - test lib/stoat/perf_results_evaluator.rb
class TestPerfResultsEvaluator < Minitest::Test
  def test_evaluate_no_issues
    ev = fresh_ev

    def ev.puts(txt)
      # :nocov: passing tests won't hit this raise
      raise "Unexpected puts input: '#{txt}'" unless txt.match?(/(?:Examining #{@path}|Parse complete, no)/)
      # :nocov:
    end

    File.stub :read, results_data_good, [path] do
      ev.evaluate
    end
  end

  def test_evaluate_with_issues
    ev = fresh_ev

    def ev.puts(txt = nil)
      return unless txt

      expected = /(?:Examining #{@path}|Parse complete. The following|SlowTest|HighAllocsTest|Overall)/
      # :nocov: passing tests won't hit this raise
      raise "Unexpected puts input: '#{txt}'" unless txt.match?(expected)
      # :nocov:
    end

    File.stub :read, results_data_bad, [path] do
      ev.evaluate
    end
  end

  def test_convert_to_microseconds_with_invalid_input
    ev = Stoat::PerfResultsEvaluator.new(path)
    def ev.warn(msg)
      # :nocov: passing tests won't hit this raise
      raise "Unexpected warn input: '#{msg}'" unless msg.match?(/^Failed to parse/)
      # :nocov:
    end
    assert_in_delta 0.0, ev.send(:convert_to_microseconds, '1.21 gw')
  end

  def test_float_to_microseconds_with_invalid_unit
    ev = fresh_ev
    def ev.warn(msg)
      # :nocov: passing tests won't hit this raise
      raise "Unexpected warn input: '#{msg}'" unless msg.match?(/^Invalid time unit/)
      # :nocov:
    end
    assert_raises(SystemExit) { ev.send(:float_to_microseconds, 0.07, 'jb') }
  end

  # helpers

  def fresh_ev
    Stoat::PerfResultsEvaluator.new(path)
  end

  def path
    '/lighthouse/on/a/craggy/rock'
  end

  def results_data_good
    <<~RESULTS_DATA_GOOD
      | name                                                                                       | before    | after     | delta | allocs_before | allocs_after | allocs_delta | retained | retained_delta |
      |--------------------------------------------------------------------------------------------|-----------|-----------|-------|---------------|--------------|--------------|----------|----------------|
      | ActiveRecordTest#test_helper_by_name                                                       |   1.32 µs |   1.32 µs | -0.3% |             4 |            4 |         0.0% |        0 |           0.0% |
      | ActiveRecordTest#test_helper_by_sql                                                        |   2.80 µs |   2.73 µs | -2.4% |             9 |            9 |         0.0% |        0 |           0.0% |
      | ActiveRecordSubscriberTest#test_subscriber_in_txn                                          |   4.10 ms |   4.09 ms | -0.1% |          1935 |         1924 |        -0.6% |        0 |           0.0% |
      | AgentAttributesTests#test_empty_agent_attributes                                           |   0.89 µs |   0.91 µs | +2.0% |             0 |            0 |         NaN% |        0 |           0.0% |
      | TransactionTracingPerfTests#test_long_transactions                                         | 530.66 s  | 533.83 s  | +0.6% |        696095 |       696113 |        +0.0% |        0 |           0.0% |
    RESULTS_DATA_GOOD
  end

  def results_data_bad
    <<~RESULTS_DATA_BAD
      | name                                                                                       | before    | after     | delta | allocs_before | allocs_after | allocs_delta | retained | retained_delta |
      |--------------------------------------------------------------------------------------------|-----------|-----------|-------|---------------|--------------|--------------|----------|----------------|
      | SlowTest#test_swimming_sloth                                                               |   1.32 µs |   1.37 µs | +4.0% |             4 |            4 |         0.0% |        0 |           0.0% |
      | ActiveRecordTest#test_helper_by_sql                                                        |   2.80 µs |   2.73 µs | -2.4% |             9 |           20 |         0.0% |        0 |           0.0% |
      | HighAllocsTest#test_elephant_recall                                                        |   4.10 ms |  14.09 ms | -0.1% |          1935 |         1973 |        +2.0% |        0 |           0.0% |
    RESULTS_DATA_BAD
  end
end
