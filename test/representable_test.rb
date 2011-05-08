require 'test_helper'

class RepresentableTest < MiniTest::Spec
  class Band
    include Representable
    representable_property :name
  end
  
  class PunkBand < Band
    representable_property :street_cred
  end
  
  
  describe "#representable_attrs" do
    it "responds to #representable_attrs" do
      assert_equal 1, Band.representable_attrs.size
      assert_equal "name", Band.representable_attrs.first.name
    end
    
    it "inherits correctly" do
      assert_equal 2, PunkBand.representable_attrs.size
      assert_equal "name", PunkBand.representable_attrs.first.name
      assert_equal "street_cred", PunkBand.representable_attrs.last.name
    end
  end
  
  describe "#representable_property" do
    it "creates accessors for the attribute" do
      @band = PunkBand.new
      assert @band.name = "Bad Religion"
      assert_equal "Bad Religion", @band.name
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
  
  
  describe "#representation_name" do
    class SoundSystem
      include Representable
    end
    
    class HardcoreBand
      include Representable
    end
  
    class SoftcoreBand < HardcoreBand
    end
    
    it "provides the root 'tag' name" do
      assert_equal "sound_system", SoundSystem.representation_name
    end
    
    it "inherits correctly" do
      HardcoreBand.representation_name = "breach"
      assert_equal "breach", HardcoreBand.representation_name
      assert_equal "breach", SoftcoreBand.representation_name
    end
  end
  
  
  describe "#definition_class" do
    it "returns Definition class" do
      assert_equal Representable::Definition, Band.definition_class
    end
    
  end
end
