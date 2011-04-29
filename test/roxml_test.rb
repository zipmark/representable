require 'test_helper'

class RoxmlTest < MiniTest::Spec
  class Band
    include ROXML
    xml_accessor :name
  end
    
  describe "#representable_attrs" do
    
    class PunkBand < Band
      xml_accessor :street_cred
    end
    
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
  
  describe "#representation_name" do
    class SoundSystem
      include ROXML
    end
    
    class HardcoreBand
      include ROXML
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
      assert_equal ROXML::Definition, Band.definition_class
    end
    
  end
  
end
