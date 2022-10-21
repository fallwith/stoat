# frozen_string_literal: true

require 'test_helper'

# TestArtifactHelpers - test lib/stoat/artifact_helpers.rb
class TestArtifactHelpers < Minitest::Test
  class TesterClass
    include Stoat::ArtifactHelpers
  end

  def test_latest_artifact_with_nil_response
    tester = prepped_tester(nil)
    assert_raises(SystemExit) { tester.latest_artifact('Sergio') }
  end

  def test_latest_artifact_with_empty_artifacts_response
    response = MiniTest::Mock.new
    response.expect :nil?, false
    response.expect :artifacts, []
    tester = prepped_tester(response)
    assert_raises(SystemExit) { tester.latest_artifact('Perez') }
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def test_latest_artifact_pagination
    name = 'Checo'

    incorrect_artifact = MiniTest::Mock.new
    incorrect_artifact.expect :name, 'Senna'
    correct_artifact = MiniTest::Mock.new
    correct_artifact.expect :name, name
    correct_artifact.expect :name, name

    page1_response = MiniTest::Mock.new
    page1_response.expect :nil?, false
    page1_response.expect :artifacts, [incorrect_artifact]
    page1_response.expect :artifacts, [incorrect_artifact]

    page2_response = MiniTest::Mock.new
    page2_response.expect :nil?, false
    page2_response.expect :artifacts, [correct_artifact]
    page2_response.expect :artifacts, [correct_artifact]

    tester = prepped_tester(page1_response, page2_response)
    assert_equal name, tester.latest_artifact(name).name

    incorrect_artifact.verify
    correct_artifact.verify
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  # helpers

  def define_methods(obj)
    def obj.github
      @fake_github
    end

    def obj.warn(_msg); end
  end

  def fake_github
    fake = []

    def fake.repository_artifacts(_repo, page:)
      case page
      when 1
        @repository_artifacts_response1
      else
        @repository_artifacts_response2
      end
    end

    fake
  end

  def prepped_tester(repository_artifacts_response1, repository_artifacts_response2 = nil)
    tester = TesterClass.new
    gh = fake_github
    gh.instance_variable_set(:@repository_artifacts_response1, repository_artifacts_response1)
    gh.instance_variable_set(:@repository_artifacts_response2, repository_artifacts_response2)
    define_methods(tester)
    tester.instance_variable_set(:@fake_github, gh)
    tester
  end
end
