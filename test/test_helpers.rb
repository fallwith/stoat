# frozen_string_literal: true

require 'test_helper'

# TestHelpers - test lib/helpers.rb
class TestHelpers < Minitest::Test
  class Tester
    include Stoat::Helpers
    attr_accessor :message
  end

  def test_bail
    tester = Tester.new
    msg = 'Fear causes hesitation, and hesitation will cause your worst fears to come true.'

    def tester.warn(message)
      self.message = message
    end

    assert_raises(SystemExit) { tester.bail msg }
    assert_equal msg, tester.message
  end
end
