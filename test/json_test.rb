require 'test_helper'
require 'representable/json'

module JsonTest
  class APITest < MiniTest::Spec
    Json = Representable::JSON
    Def = Representable::Definition
    
    describe "JSON module" do
      before do
        @Band = Class.new(Band) do
          self.representation_name= :band
          representable_property :label
        end
      end
      
      class Band
        include Representable::JSON
        representable_property :name
      end
        
      describe "#binding_for_definition" do
        it "returns ObjectBinding" do
          assert_kind_of Json::ObjectBinding, Band.binding_for_definition(Def.new(:band, :as => Hash))
        end
        
        it "returns TextBinding" do
          assert_kind_of Json::TextBinding, Band.binding_for_definition(Def.new(:band))
        end
      end
      
      describe "#representable_bindings" do
        it "returns bindings for each property" do
          assert_equal 1, Band.representable_bindings.size
          assert_equal "name", Band.representable_bindings.first.definition.name
        end
      end
      
      describe "#from_json" do
        before do
          @band = @Band.new
        end
        
        it "accepts json string" do
          @band.from_json({band: {name: "Nofx", label: "NOFX"}}.to_json)
          assert_equal ["Nofx", "NOFX"], [@band.name, @band.label]
        end
        
        it "forwards block to #update_properties_from" do
          @band.from_json({band: {name: "Nofx", label: "NOFX"}}.to_json) do |binding|
            binding.definition.name == "name"
          end
          
          assert_equal ["Nofx", nil], [@band.name, @band.label]
        end
        
        describe ":wrap option" do
          it "accepts wrapped properties" do
            band = Band.new
            band.from_json({:band => {:name => "This Is A Standoff"}}.to_json)
            assert_equal "This Is A Standoff", band.name
          end
          
          it "accepts unwrapped properties" do # DISCUSS: should be default.
            band = Band.new
            band.from_json({name: "This Is A Standoff"}.to_json, :wrap => false)
            assert_equal "This Is A Standoff", band.name
          end
        end
      end
      
      
      describe ".from_json" do
        it "delegates to #from_json after object conception" do
          band = @Band.from_json({band: {name: "Nofx", label: "NOFX"}}.to_json) do |binding| binding.definition.name == "name" end
          assert_equal ["Nofx", nil], [band.name, band.label]
        end
        
        it "passes all args to #from_json" do
          block = lambda {|a,b|}
          @Band.any_instance.expects(:from_json).with("{}", "yo") # FIXME: how to expect block?
          @Band.from_json("{}", "yo", &block)
        end
        
        # TODO: move following tests to #from_json test.
        it "raises error with emtpy string" do
          assert_raises JSON::ParserError do
            Band.from_json("")
          end
        end
        
        it "returns empty hash with inappropriate hash" do
          assert Band.from_json({:song => "Message In A Bottle"}.to_json)
        end
        
        it "generates warning with inappropriate hash in debugging mode" do
        end
      end
      
      
      describe ".from_hash" do
        it "accepts unwrapped hash with string keys" do
          band = Band.from_hash("name" => "Bombshell Rocks")
          assert_equal "Bombshell Rocks", band.name
        end
      end
    
    
      describe "#to_json" do
        it "respects :wrap" do
          band = @Band.new
          band.label = "Fat"
          
          assert_equal "{\"label\":\"Fat\"}", band.to_json(:wrap => false)
        end
      end
    end
  end

  class PropertyTest < MiniTest::Spec
    describe "representable_property :name" do
      class Band
        include Representable::JSON
        representable_property :name
      end
      
      it "#from_json creates correct accessors" do
        band = Band.from_json({:band => {:name => "Bombshell Rocks"}}.to_json)
        assert_equal "Bombshell Rocks", band.name
      end
      
      it "#to_json serializes correctly" do
        band = Band.new
        band.name = "Cigar"
        
        assert_equal '{"band":{"name":"Cigar"}}', band.to_json
      end
    end
    
    describe ":as => Item" do
      class Label
        include Representable::JSON
        representable_property :name
      end
      
      class Album
        include Representable::JSON
        representable_property :label, :as => Label
      end
      
      it "#from_json creates one Item instance" do
        album = Album.from_json('{"album":{"label":{"name":"Fat Wreck"}}}')
        assert_equal "Fat Wreck", album.label.name
      end
      
      it "#to_json serializes" do
        label = Label.new; label.name = "Fat Wreck"
        album = Album.new; album.label = label
        
        assert_equal '{"album":{"label":{"name":"Fat Wreck"}}}', album.to_json
      end
    end
    
    describe ":from => :songName" do
      class Song
        include Representable::JSON
        representable_property :name, :from => :songName
      end
      
      it "respects :from in #from_json" do
        song = Song.from_json({:song => {:songName => "Run To The Hills"}}.to_json)
        assert_equal "Run To The Hills", song.name
      end
      
      it "respects :from in #to_json" do
        song = Song.new; song.name = "Run To The Hills"
        assert_equal '{"song":{"songName":"Run To The Hills"}}', song.to_json
      end
    end
  end


  class CollectionTest < MiniTest::Spec
    describe "representable_collection :name" do
      class CD
        include Representable::JSON
        representable_collection :songs
      end
      
      it "#from_json creates correct accessors" do
        cd = CD.from_json({:cd => {:songs => ["Out in the cold", "Microphone"]}}.to_json)
        assert_equal ["Out in the cold", "Microphone"], cd.songs
      end
    
      it "#to_json serializes correctly" do
        cd = CD.new
        cd.songs = ["Out in the cold", "Microphone"]
        
        assert_equal '{"cd":{"songs":["Out in the cold","Microphone"]}}', cd.to_json
      end
    end
    
    describe "representable_collection :name, :as => Band" do
      class Band
        include Representable::JSON
        representable_property :name
        
        def initialize(name="")
          self.name = name
        end
      end
      
      class Compilation
        include Representable::JSON
        representable_collection :bands, :as => Band
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
        
        assert_equal '{"compilation":{"bands":[{"name":"Diesel Boy"},{"name":"Bad Religion"}]}}', cd.to_json
      end
    end
    
    
    describe ":from => :songList" do
      class Songs
        include Representable::JSON
        representable_collection :tracks, :from => :songList
      end
      
      it "respects :from in #from_json" do
        songs = Songs.from_json({:songs => {:songList => ["Out in the cold", "Microphone"]}}.to_json)
        assert_equal ["Out in the cold", "Microphone"], songs.tracks
      end
    
      it "respects option in #to_json" do
        songs = Songs.new
        songs.tracks = ["Out in the cold", "Microphone"]
        
        assert_equal '{"songs":{"songList":["Out in the cold","Microphone"]}}', songs.to_json
      end
    end
  end
end
