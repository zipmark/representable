require 'test_helper'
require 'representable/coercion'

class VirtusCoercionTest < MiniTest::Spec
  class Song  # note that we don't define accessors for the properties here.
  end
    
  describe "Coercion with Virtus" do
    #before do
    #  module SongRepresenter
    #    include Representable::JSON
    #    include Representable::Coercion
    #    property :composed_at, :type => DateTime 
    #  end
    #end
   # 
   # it "coerces properties in #from_json" do
   #   song = Song.new.extend(SongRepresenter).from_json("{\"composed_at\":\"November 18th, 1983\"}")
   #   assert_kind_of DateTime, song.composed_at
   #   assert_equal "expected", song.composed_at
   # end
    class ImmigrantSong
      include Representable::JSON
      include Virtus
      extend Representable::Coercion::ClassMethods
      
      property :composed_at, :type => DateTime 
    end
   
  end
end
