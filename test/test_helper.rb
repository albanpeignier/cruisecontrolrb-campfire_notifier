ENV["ENV"] = "test"
require 'rubygems'
require 'shoulda'
require 'mocha'

class Test::Unit::TestCase
end

class BuilderPlugin; end

module CruiseControl
  class Log
    def self.debug(message)
      true
    end
  end
end

class Configuration
  def self.dashboard_url
    "http://tempuri.org"
  end
end

class Revision
  attr_accessor :committed_by
  def initialize(committed_by)
    @committed_by = committed_by
  end
end

module SourceControl
  class LogParser
    def parse(changeset_array)
      a = []
      for k in 1..20
        revision = Revision.new('committerabc')
        a << revision
      end
      a
    end
  end
end
