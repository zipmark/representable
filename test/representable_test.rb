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
    class SoundSystem
      include Representable
    end
    
    class HardcoreBand
      include Representable
    end
  
    class SoftcoreBand < HardcoreBand
    end
    
    it "returns false per default" do
      assert_equal nil, SoundSystem.representation_wrap
    end
    
    it "infers a printable class name if set to true" do
      HardcoreBand.representation_wrap = true
      assert_equal "hardcore_band", HardcoreBand.send(:representation_wrap)
    end
    
    it "can be set explicitely" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal "breach", HardcoreBand.representation_wrap
    end
    
    it "doesn't inherit correctly" do
      HardcoreBand.representation_wrap = "breach"
      assert_equal nil, SoftcoreBand.representation_wrap
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
    it "copies values from document to object" do
      band = PopBand.new
      band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2})
      assert_equal "No One's Choice", band.name
      assert_equal 2, band.groupies
    end
    
    it "skips elements when block returns false" do
      band = PopBand.new
      band.update_properties_from({"name"=>"No One's Choice", "groupies"=>2}) do |name|
        name == :name
      end
      assert_equal "No One's Choice", band.name
      assert_equal nil, band.groupies
    end
    
    it "always returns self" do
      band = PopBand.new
      assert_equal band, band.update_properties_from({"name"=>"Nofx"})
    end
  end
  
  describe "#create_representation_with" do
    before do
      @band = PopBand.new
      @band.name = "No One's Choice"
      @band.groupies = 2
    end
    
    it "compiles document from properties in object" do
      assert_equal({"name"=>"No One's Choice", "groupies"=>2}, @band.send(:create_representation_with, {}))
    end
    
    it "skips elements when block returns false" do
      assert_equal({"name"=>"No One's Choice"}, @band.send(:create_representation_with, {}) do |name| name == :name end)
    end
  end
  
end
