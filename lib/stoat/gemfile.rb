# frozen_string_literal: true

require 'octokit'

require_relative 'gemfile_helpers'
require_relative 'helpers'

module Stoat
  # Gemfile - for updating Gemfile and other project files
  class Gemfile
    include GemfileHelpers
    include Helpers

    attr_reader :data, :path

    def initialize(path = nil)
      @path = path || Dir.pwd
      @data = { original: {}, modified: {} }
    end

    def go
      read_files
      modify_files
    end

    private

    def file_class
      File
    end

    def fileutils_class
      FileUtils
    end

    def modify_files
      modify_data
      overwrite_files
    end

    def overwrite_files
      [GEMFILE, LOCKFILE, PAPERSFILE].each do |file|
        verify_file_changes(file)
        full = file_class.join(path, file)
        fileutils_class.rm_f(full)
        file_class.write(full, data[:modified][file].join)
      end
    end

    def read_file(full_path, filename)
      data[:original][filename] = file_class.read(full_path).lines
      data[:modified][filename] = []
    end

    def read_files
      [GEMFILE, LOCKFILE, PAPERSFILE].each do |file|
        full = file_class.join(path, file)
        bail "No '#{file}' file found at #{path}!" unless file_class.exist?(full)

        read_file(full, file)
      end
    end

    def release_query
      <<~QUERY
        query {
          repository(owner: "#{repo_owner}", name: "#{repo_name}") {
            releases(last: 1, orderBy: { field: CREATED_AT, direction: ASC }) {
              nodes {
                name
                tagCommit { oid }
              }
            }
          }
        }
      QUERY
    end

    def repo_owner
      @repo_owner ||= REPO.split('/').first
    end

    def repo_name
      @repo_name ||= REPO.split('/').last
    end

    def verify_file_changes(file)
      bail "Failed to modify '#{file}'!" if data[:original][file] == data[:modified][file]
    end
  end
end
