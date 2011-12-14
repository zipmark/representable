require 'bundler'
Bundler.setup

gem 'minitest'
require 'representable'
require 'test/unit'
require 'minitest/spec'
require 'minitest/autorun'
require 'test_xml/mini_test'
require 'mocha'

class Album
  def initialize(*songs)
    @songs      = songs
    @best_song  = songs.last
  end
end

class Song
  def initialize(name=nil)
    @name = name
  end
end
