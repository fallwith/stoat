# frozen_string_literal: true

module Stoat
  # Helpers: helper methods for use by all subcommands
  module Helpers
    def bail(msg)
      warn msg
      exit(1)
    end
  end
end
