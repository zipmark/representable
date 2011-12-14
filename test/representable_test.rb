require 'test_helper'

class RepresentableTest < MiniTest::Spec
  class Band
    include Representable
    representable_property :name
  end
  
  class PunkBand < Band
    representable_property :street_cred
  end
  
  module BandRepresentation
    include Representable
    
    representable_property :name
  end
  
  module PunkBandRepresentation
    include Representable
    include BandRepresentation
    
    representable_property :street_cred
  end
  
  
  describe "#representable_attrs" do
    it "responds to #representable_attrs" do
      assert_equal 1, Band.representable_attrs.size
      assert_equal "name", Band.representable_attrs.first.name
    end
    
    describe "in module" do
      it "returns definitions" do
        assert_equal 1, BandRepresentation.representable_attrs.size
        assert_equal "name", BandRepresentation.representable_attrs.first.name
      end
      
      it "inherits to including modules" do
        assert_equal 2,  PunkBandRepresentation.representable_attrs.size
        assert_equal "name", PunkBandRepresentation.representable_attrs.first.name
        assert_equal "street_cred", PunkBandRepresentation.representable_attrs.last.name
      end
      
      it "inherits to including class" do
        band = Class.new do
          include Representable
          include PunkBandRepresentation
        end
        
        assert_equal 2,  band.representable_attrs.size
        assert_equal "name", band.representable_attrs.first.name
        assert_equal "street_cred", band.representable_attrs.last.name
      end
      
      it "allows including the concrete representer module later" do
        require 'representable/json'
        vd = class VD
          include Representable::JSON
          include PunkBandRepresentation
        end.new
        vd.name        = "Vention Dention"
        vd.street_cred = 1
        assert_equal "{\"name\":\"Vention Dention\",\"street_cred\":1}", vd.to_json
      end
      
      #it "allows including the concrete representer module only" do
      #  require 'representable/json'
      #  module RockBandRepresentation
      #    include Representable::JSON
      #    representable_property :name
      #  end
      #  vd = class VH
      #    include RockBandRepresentation
      #  end.new
      #  vd.name        = "Van Halen"
      #  assert_equal "{\"name\":\"Van Halen\"}", vd.to_json
      #end
    end
    
    
    describe "DCI" do
      require 'representable/json'
      module SongRepresenter
        include Representable::JSON
        representable_property :name
      end
      
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
      
      module AlbumRepresenter
        include Representable::JSON
        representable_property :best_song, :as => Song, :extend => SongRepresenter
        representable_collection :songs, :as => Song, :extend => SongRepresenter
      end
      
      
      it "allows adding the representer by using #extend" do
        module BandRepresenter
          include Representable::JSON
          representable_property :name
        end
        
        civ = Object.new
        civ.instance_eval do
          def name; "CIV"; end
        end
        
        civ.extend(BandRepresenter)
        assert_equal "{\"name\":\"CIV\"}", civ.to_json
      end
      
      it "extends contained models when serializing" do
        @album = Album.new(Song.new("I Hate My Brain"), Song.new("Mr. Charisma"))
        @album.extend(AlbumRepresenter)
        
        assert_equal "{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}", @album.to_json
      end
      
      it "extends contained models when deserializing" do
        #@album = Album.new(Song.new("I Hate My Brain"), Song.new("Mr. Charisma"))
        @album = Album.new
        @album.extend(AlbumRepresenter)
        
        @album.from_json("{\"best_song\":{\"name\":\"Mr. Charisma\"},\"songs\":[{\"name\":\"I Hate My Brain\"},{\"name\":\"Mr. Charisma\"}]}")
        assert_equal "Mr. Charisma", @album.best_song.name
      end
    end
    
    
    #class Album
    #  extend Representable::Represents
    #  represents :json, :with => AlbumRepresenter
    #end
    #
    #class Song
    #  extend Representable::Represents
    #  represents :json, :with => SongRepresenter
    #end
  end
  
  
  describe "#representable_property" do
    it "creates accessors for the attribute" do
      @band = PunkBand.new
      assert @band.name = "Bad Religion"
      assert_equal "Bad Religion", @band.name
    end
    
    describe ":from" do
      # TODO: do this with all options.
      it "can be set explicitly" do
        band = Class.new(Band) { representable_property :friends, :from => :friend }
        assert_equal "friend", band.representable_attrs.last.from
      end
      
      it "is infered from the name implicitly" do
        band = Class.new(Band) { representable_property :friends }
        assert_equal "friends", band.representable_attrs.last.from
      end
    end
    
    describe ":accessor" do
      it "doesn't add methods when false" do
        klass = Class.new(Band) { representable_property :friends, :accessors => false }
        band = klass.new
        assert ! band.respond_to?(:friends)
        assert ! band.respond_to?("friends=")
      end
    end
  end
  
  describe "#representable_collection" do
    class RockBand < Band
      representable_collection :albums
    end
    
    it "creates correct Definition" do
      assert_equal "albums", RockBand.representable_attrs.last.name
      assert RockBand.representable_attrs.last.array?
    end
  end
  
  
  describe "#representation_wrap" do
    class HardcoreBand
      include Representable
    end
  
    class SoftcoreBand < HardcoreBand
    end
    
    before do
      @band = HardcoreBand.new
    end
    
    
    it "returns false per default" do
      assert_equal nil, SoftcoreBand.new.send(:representation_wrap)
    end
    
    it "infers a printable class name if set to true" do
      HardcoreBand.representation_wrap = true
      assert_equal "hardcore_band", @band.send(:representation_wrap)
    end
    
    it "can be set explicitely" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal "breach", @band.send(:representation_wrap)
    end
  end
  
  
  describe "#definition_class" do
    it "returns Definition class" do
      assert_equal Representable::Definition, Band.definition_class
    end
  end

  
  require 'representable/json'  # DISCUSS: i don't like the JSON requirement here, what about some generic test module?
  class PopBand
    include Representable::JSON
    representable_property :name
    representable_property :groupies
  end

  describe "#update_properties_from" do
    before do
      @band = PopBand.new
    end
    
    it "copies values from document to object" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, {})
      assert_equal "No One's Choice", @band.name
      assert_equal 2, @band.groupies
    end
    
    it "accepts :except option" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, :except => [:groupies])
      assert_equal "No One's Choice", @band.name
      assert_equal nil, @band.groupies
    end
    
    it "accepts :include option" do
      @band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}, :include => [:groupies])
      assert_equal 2, @band.groupies
      assert_equal nil, @band.name
    end
    
    it "always returns self" do
      assert_equal @band, @band.update_properties_from({"name"=>"Nofx"}, {})
    end
  end
  
  describe "#create_representation_with" do
    before do
      @band = PopBand.new
      @band.name = "No One's Choice"
      @band.groupies = 2
    end
    
    it "compiles document from properties in object" do
      assert_equal({"name"=>"No One's Choice", "groupies"=>2}, @band.send(:create_representation_with, {}, {}))
    end
    
    it "accepts :except option" do
      hash = @band.send(:create_representation_with, {}, :except => [:groupies])
      assert_equal({"name"=>"No One's Choice"}, hash)
    end
    
    it "accepts :include option" do
      hash = @band.send(:create_representation_with, {}, :include => [:groupies])
      assert_equal({"groupies"=>2}, hash)
    end
  end
  
  
  describe "Config" do
    before do
      @config = Representable::Config.new
      PunkRock = Class.new
    end
    
    describe "wrapping" do
      it "returns false per default" do
        assert_equal nil, @config.wrap_for("Punk")
      end
      
      it "infers a printable class name if set to true" do
        @config.wrap = true
        assert_equal "punk_rock", @config.wrap_for(PunkRock)
      end
      
      it "can be set explicitely" do
        @config.wrap = "Descendents"
        assert_equal "Descendents", @config.wrap_for(PunkRock)
      end
    end
  end
  
  describe "Represents" do
    before do
      @class = Class.new do
        extend Representable::Represents
        represents :json, :with => :whatever
        represents "application/order-json", :with => :special
      end
    end
    
    it "allows mapping formats to representers" do
      assert_equal :whatever, @class.representer[:json]
      assert_equal :special, @class.representer["application/order-json"]
    end
  end
end
