# frozen_string_literal: true

require 'test_helper'

# TestHelpers - test lib/helpers.rb
class TestHelpers < Minitest::Test
  class Tester
    include Stoat::Helpers
    attr_accessor :message
  end

  def test_access_token
    value = 'Slippers weather'
    ENV.stub :key, true, [Stoat::Helpers::TOKEN_ENV_VAR] do
      ENV.stub :fetch, value, [Stoat::Helpers::TOKEN_ENV_VAR] do
        assert_equal value, Tester.new.access_token
      end
    end
  end

  def test_access_token_with_env_var_not_set
    ENV.stub :key?, false, [Stoat::Helpers::TOKEN_ENV_VAR] do
      tester = Tester.new
      def tester.warn(_msg); end
      assert_raises(SystemExit) { tester.access_token }
    end
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

  def test_github
    token = 'NES Kirby'
    tester = Tester.new
    tester.instance_variable_set(:@token, token)

    def tester.access_token
      @token
    end

    gh = tester.github
    assert_kind_of Octokit::Client, gh
    assert_equal token, gh.access_token
  end
end
