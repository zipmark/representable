require 'test_helper'

class BindingsTest < MiniTest::Spec
  describe "TextRef#read" do
    def parse_xml(xml); Nokogiri::XML(xml).root; end
    
    before do
      @ref = Representable::XML::TextBinding.new(Representable::Definition.new(:song))
    end
    
    it "returns found value" do
      assert_equal "Unkoil", @ref.read(parse_xml("<a><song>Unkoil</song></a>"))
    end
  end
  
  describe "JSON::Binding" do
    module SongRepresenter
      include Representable::JSON
      property :name
    end
    
    describe "#write" do
      it "returns the written property" do
        @ref = Representable::JSON::TextBinding.new(Representable::Definition.new(:song))
        assert_equal("Unkoil", @ref.write({}, "Unkoil"))
        
        @ref = Representable::JSON::ObjectBinding.new(Representable::Definition.new(:song, :class => Song, :extend => SongRepresenter))
        assert_equal({"name"=>"Unkoil"}, @ref.write({}, Song.new("Unkoil")))
      end
    end
    
  end
  
end

