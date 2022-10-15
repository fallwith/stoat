# frozen_string_literal: true

require 'octokit'

module Stoat
  # Helpers: helper methods for use by all subcommands
  module Helpers
    TOKEN_ENV_VAR = 'NR_GITHUB_TOKEN'
    REPO = 'newrelic/newrelic-ruby-agent'

    def access_token
      @access_token ||= begin
        bail "GitHub Access Token env var '#{TOKEN_ENV_VAR}' not set!" unless ENV.key?(TOKEN_ENV_VAR)

        ENV.fetch(TOKEN_ENV_VAR)
      end
    end

    def bail(msg)
      warn msg
      exit(1)
    end

    def github
      @github ||= Octokit::Client.new(access_token:)
    end
  end
end
