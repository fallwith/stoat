# frozen_string_literal: true

require 'fileutils'
require 'json'

require_relative 'artifact_helpers'
require_relative 'helpers'

module Stoat
  # Coverage - for fetching the most recent test coverage artifact
  class Coverage
    include ArtifactHelpers
    include Helpers

    ARTIFACT = 'coverage-report-combined'

    def go
      puts 'Fetching latest code coverage data...'
      fetch_artifact(ARTIFACT)
      puts "Results downloaded to #{ARTIFACT}"
      cmd = "open #{ARTIFACT}/index.html"
      puts cmd
      exec cmd
    end
  end
end
