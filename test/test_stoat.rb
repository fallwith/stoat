# frozen_string_literal: true

require 'test_helper'

# TestStoat - test lib/stoat.rb
class TestStoat < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Stoat::VERSION
  end
end
