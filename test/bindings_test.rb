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
end

