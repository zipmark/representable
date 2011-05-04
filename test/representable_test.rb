require 'test_helper'

class Band
  include Representable
  xml_accessor :name
  
  def initialize(name=nil)
    name and self.name = name
  end
end

class Label
  def to_xml
    "<label>Fat Wreck</label>"
  end
end
  
  
class RepresentableTest < MiniTest::Spec
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
