# frozen_string_literal: true

require 'fileutils'
require 'zip'

require_relative 'helpers'

module Stoat
  # ArtifactHelpers - common methods related to GitHub Actions artifacts
  module ArtifactHelpers
    include Helpers

    def artifact_url(artifact_name)
      latest_artifact(artifact_name).archive_download_url
    end

    def fetch_artifact(artifact_name, cleanup_routine: nil)
      blob = grab_latest_zip_blob(artifact_name)
      store_zip(artifact_name, blob)
      unzip_zip(artifact_name)
      run_cleanup(artifact_name, cleanup_routine)
    end

    def file_utils
      @file_utils ||= FileUtils
    end

    def grab_latest_zip_blob(artifact_name)
      github.get(artifact_url(artifact_name))
    end

    def latest_artifact(artifact_name)
      page = 0
      loop do
        response = github.repository_artifacts(REPO, page: page += 1)
        if response.nil? || response.artifacts.empty?
          bail "Could not find any artifacts named '#{artifact_name}' after #{page} page(s)!"
        end
        match = response.artifacts.detect { |a| a.name == artifact_name }
        break match if match
      end
    end

    def perform_in_dir(dir)
      opwd = Dir.pwd
      Dir.chdir dir
      yield
    ensure
      Dir.chdir opwd
    end

    def run_cleanup(artifact_name, cleanup_routine)
      perform_in_dir(artifact_name) { cleanup_routine&.call }
    end

    def store_zip(artifact_name, blob)
      FileUtils.rm_rf artifact_name
      FileUtils.mkdir artifact_name
      perform_in_dir(artifact_name) { File.write("#{artifact_name}.zip", blob) }
    end

    def unzip_zip(artifact_name)
      perform_in_dir(artifact_name) do
        zip = "#{artifact_name}.zip"
        Zip::File.open(zip) { |z| z.map(&:extract) }
        file_utils.rm_rf(zip)
      end
    end
  end
end
