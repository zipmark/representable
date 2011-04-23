require 'test_helper'

class RoxmlTest < MiniTest::Spec
  class Band
    include ROXML
    xml_accessor :name
  end
    
  describe "#roxml_attrs" do
    
    class PunkBand < Band
      xml_accessor :street_cred
    end
    
    it "responds to #roxml_attrs" do
      assert_equal 1, Band.roxml_attrs.size
      assert_equal "name", Band.roxml_attrs.first.name
    end
    
    it "inherits correctly" do
      assert_equal 2, PunkBand.roxml_attrs.size
      assert_equal "name", PunkBand.roxml_attrs.first.name
      assert_equal "street_cred", PunkBand.roxml_attrs.last.name
    end
  end
  
  describe "#definition_class" do
    it "returns Definition class" do
      assert_equal ROXML::Definition, Band.definition_class
    end
    
  end
  
end
