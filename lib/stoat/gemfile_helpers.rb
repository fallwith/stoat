# frozen_string_literal: true

module Stoat
  # GemfileHelpers: helper methods for use by Stoat::Gemfile
  module GemfileHelpers
    GEMFILE = 'Gemfile'
    LOCKFILE = 'Gemfile.lock'
    PAPERSFILE = 'config/papers_manifest.yml'

    def inside_desired_git_block?(line)
      return true if @inside_desired_git_block

      # return true on the next line, false for this one
      @inside_desired_git_block = true if line.match?(%r{newrelic/newrelic-ruby-agent})
      false
    end

    def latest_release
      @latest_release ||= begin
        response = github.post '/graphql', { query: release_query }.to_json
        response.data.repository.releases.nodes.first
      end
    rescue StandardError => e
      bail "Failed to fetch latest release for '#{Stoat::Helpers::REPO}' from GitHub: #{e.class} - #{e.message}"
    end

    def latest_sha
      @latest_sha ||= latest_release.tagCommit.oid
    end

    def latest_version
      @latest_version ||= latest_release.name
    end

    def latest_version_without_pre
      latest_version.sub(/-pre$/, '')
    end

    def lockfile_processing_complete?
      @lockfile_processing_complete
    end

    def modify_data
      modify_data_gemfile
      modify_data_lockfile
      modify_data_papersfile
    end

    def modify_data_gemfile
      data[:original][GEMFILE].each do |line|
        data[:modified][GEMFILE] << modify_data_gemfile_line(line)
      end
    end

    def modify_data_gemfile_line(line)
      return line unless line =~ /^(\s*gem 'newrelic(?:_rpm|-infinite_tracing)', git: .*?, tag: )(['"])[^'"]+['"](.*?)$/

      start = Regexp.last_match(1)
      quote = Regexp.last_match(2)
      finish = Regexp.last_match(4)
      "#{start}#{quote}#{latest_version}#{quote}#{finish}\n"
    end

    def modify_data_lockfile
      data[:original][LOCKFILE].each_with_index do |line, idx|
        process_lockfile_line(line)
        if lockfile_processing_complete?
          data[:modified][LOCKFILE] += data[:original][LOCKFILE][idx..]
          break
        end
      end
    end

    def process_lockfile_line(line)
      return data[:modified][LOCKFILE] << line unless inside_desired_git_block?(line)

      if line.start_with?('GIT')
        @lockfile_processing_complete = true
        return
      end

      data[:modified][LOCKFILE] << modify_data_lockfile_line(line)
      false
    end

    def modify_data_lockfile_line(line)
      case line
      when /revision: (\w+)/
        line.sub(Regexp.last_match(1), latest_sha)
      when /tag: (.*)/
        line.sub(Regexp.last_match(1), latest_version)
      when /newrelic-infinite_tracing \((.*?)\)/, /newrelic_rpm \((?:= )?(.*?)\)/
        line.sub(Regexp.last_match(1), latest_version_without_pre)
      else
        line
      end
    end

    def modify_data_papersfile
      @papers_modifications = 0
      data[:original][PAPERSFILE].each_with_index do |line, idx|
        process_papers_line(line)
        if @papers_modifications == 2
          data[:modified][PAPERSFILE] += data[:original][PAPERSFILE][(idx + 1)..]
          break
        end
      end
    end

    def process_papers_line(line)
      if line =~ /^(\s*newrelic(?:_rpm|-infinite_tracing)-)[^:]+(:.*)$/
        data[:modified][PAPERSFILE] << "#{Regexp.last_match(1)}#{latest_version_without_pre}#{Regexp.last_match(2)}\n"
        @papers_modifications += 1
      else
        data[:modified][PAPERSFILE] << line
      end
    end
  end
end
