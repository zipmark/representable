require 'test_helper'
require 'representable/json'

module JsonTest
  class APITest < MiniTest::Spec
    Json = Representable::Json
    Def = Representable::Definition
    
    describe "Xml module" do
      describe "#binding_for_definition" do
        it "returns ObjectBinding" do
          assert_kind_of Json::ObjectBinding, Json.binding_for_definition(Def.new(:band, :as => Hash))
        end
        
        it "returns TextBinding" do
          assert_kind_of Json::TextBinding, Json.binding_for_definition(Def.new(:band))
        end
      end
    end
  end

  class PropertyTest < MiniTest::Spec
    describe "property :name" do
      class Band
        include Representable::Json
        json_accessor :name
      end
      
      it "#from_json creates correct accessors" do
        band = Band.from_json({:band => {:name => "Bombshell Rocks"}}.to_json)
        assert_equal "Bombshell Rocks", band.name
      end
    
      it "#to_json serializes correctly" do
        band = Band.new
        band.name = "Cigar"
        
        assert_equal "{\"band\"=>{\"name\"=>\"Cigar\"}}", band.to_json.to_s
      end
    end
    
    describe "property :name, :as => []" do
      class CD
        include Representable::Json
        json_accessor :songs, :as => []
      end
      
      it "#from_json creates correct accessors" do
        cd = CD.from_json({:cd => {:songs => ["Out in the cold", "Microphone"]}}.to_json)
        assert_equal ["Out in the cold", "Microphone"], cd.songs
      end
    
      it "#to_json serializes correctly" do
        cd = CD.new
        cd.songs = ["Out in the cold", "Microphone"]
        
        assert_equal "{\"cd\"=>{\"songs\"=>[\"Out in the cold\", \"Microphone\"]}}", cd.to_json.to_s
      end
    end
  end

  class TypedPropertyTest < MiniTest::Spec
    describe ":as => Item" do
      class Label
        include Representable::Json
        json_accessor :name
      end
      
      class Album
        include Representable::Json
        json_accessor :label, :as => Label
      end
      
      it "#from_json creates one Item instance" do
        album = Album.from_json({:album => {:label => "Fat Wreck"}}.to_json)
        assert_equal "Bad Religion", album.label.name
      end
      
      describe "#to_json" do
        it "serializes" do
          label = Label.new; label.name = "Fat Wreck"
          album = Album.new; album.label = label
          
          assert_equal "{\"album\"=>{\"label\"=>{\"name\"=>\"Fat Wreck\"}}}", album.to_json.to_s
        end
      end
    end
  end


  class CollectionTest < MiniTest::Spec
    describe ":as => [Band]" do
      class Band
        include Representable::Json
        json_accessor :name
        
        def initialize(name="")
          self.name = name
        end
      end
      
      class Compilation
        include Representable::Json
        json_accessor :bands, :as => [Band]
      end
      
      describe "#from_json" do
        it "pushes collection items to array" do
          cd = Compilation.from_json({:compilation => {:bands => [
            {:name => "Cobra Skulls"},
            {:name => "Diesel Boy"}]}}.to_json)
          assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
        end
        
        it "collections can be empty" do
          cd = Compilation.from_json({:compilation => {}}.to_json)
          assert_equal [], cd.bands
        end
      end
      
      it "responds to #to_json" do
        cd = Compilation.new
        cd.bands = [Band.new("Diesel Boy"), Band.new("Bad Religion")]
        
        assert_equal "{\"compilation\"=>{\"bands\"=>[{\"name\"=>\"Diesel Boy\"}, {\"name\"=>\"Bad Religion\"}]}}", cd.to_json.to_s
      end
    end
      
  end
end
