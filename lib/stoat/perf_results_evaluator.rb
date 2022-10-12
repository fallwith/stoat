# frozen_string_literal: true

require_relative 'helpers'

module Stoat
  # PerfResultsEvaluator - for evaluating performance test results
  class PerfResultsEvaluator
    include Helpers

    TIME_THRESHOLD = 3.0
    ALLOCS_THRESHOLD = 1.0

    def initialize(path)
      @path = path
    end

    def evaluate
      puts "Examining #{@path}..."
      lines = File.read(@path).split("\n")[2..].map { |l| l.split(/\s*\|\s*/) }
      lines.each { |line| verify_line(line) }
      verify_tallies
      report_issues
    end

    private

    def convert_to_microseconds(string)
      unless string =~ /(\d+\.?\d*) ((?:µ|m)?s)/
        warn "Failed to parse elapsed time value from string '#{string}'!"
        return 0.0
      end
      value = Regexp.last_match(1).to_f
      unit = Regexp.last_match(2)
      float_to_microseconds(value, unit)
    end

    def float_to_microseconds(value, unit)
      case unit
      when 'µs'
        value
      when 'ms'
        value * 1000
      when 's'
        value * 1000 * 1000
      else
        bail "Invalid time unit '#{unit}' received!"
      end
    end

    def issues
      @issues ||= []
    end

    def report_issues
      if issues.empty?
        puts 'Parse complete, no performance issues found!'
      else
        puts 'Parse complete. The following issues were observed:'
        issues.each { |issue| puts "  #{issue}" }
        puts
      end
    end

    def tallies
      @tallies ||= { time: { before: 0.0, after: 0.0 }, allocs: { before: 0.0, after: 0.0 } }
    end

    def tally_time(before, after)
      tallies[:time][:before] += convert_to_microseconds(before)
      tallies[:time][:after] += convert_to_microseconds(after)
    end

    def tally_allocs(before, after)
      tallies[:allocs][:before] += before.to_f
      tallies[:allocs][:after] += after.to_f
    end

    def verify_allocs(test, delta, before, after)
      delta = delta.match?('NaN') ? 0 : delta.to_f
      issues << "#{test} went from having #{before} to #{after} (a #{delta} increase)!" if delta > ALLOCS_THRESHOLD
    end

    def verify_allocs_tallies
      before = tallies[:allocs][:before]
      after = tallies[:allocs][:after]
      percentage = (after * 100) / before
      return unless (percentage - 100) > ALLOCS_THRESHOLD

      issues << "Overall allocs went from #{before} to #{after} (a #{percentage}% increase)!"
    end

    def verify_line(elements)
      test, time_before, time_after, time_delta, allocs_before, allocs_after, allocs_delta = elements[1..7]
      verify_time(test, time_delta, time_before, time_after)
      verify_allocs(test, allocs_delta, allocs_before, allocs_after)
      tally_time(time_before, time_after)
      tally_allocs(allocs_before, allocs_after)
    end

    def verify_tallies
      verify_time_tallies
      verify_allocs_tallies
    end

    def verify_time(test, delta, before, after)
      delta = delta.to_f
      issues << "#{test} went from taking #{before} to #{after} (#{delta} slower)!" if delta > TIME_THRESHOLD
    end

    def verify_time_tallies
      before = tallies[:time][:before]
      after = tallies[:time][:after]
      percentage = (after * 100) / before
      return unless (percentage - 100) > TIME_THRESHOLD

      issues << "Overall time went from being #{before} to #{after} (a #{percentage}% increase)!"
    end
  end
end
