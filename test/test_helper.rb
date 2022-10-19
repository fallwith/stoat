# frozen_string_literal: true

require 'simplecov' unless ENV['NOCOV']

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'stoat'

require 'minitest/autorun'
