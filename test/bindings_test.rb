require 'test_helper'

class BindingsTest < MiniTest::Spec
  describe "ObjectRef with []" do
    before do
      @ref = Representable::XML::ObjectBinding.new(Representable::Definition.new(:songs, :as => [Hash]))
    end
      
    it "responds to #default" do
      assert_equal [], @ref.send(:default)
    end
  end
  
  
  describe "TextRef#value_in" do
    def parse_xml(xml); Nokogiri::XML::Node.from(xml); end
    
    before do
      @ref = Representable::XML::TextBinding.new(Representable::Definition.new(:song))
    end
    
    it "returns found value" do
      assert_equal "Unkoil", @ref.value_in(parse_xml("<a><song>Unkoil</song></a>"))
    end
  end
end

