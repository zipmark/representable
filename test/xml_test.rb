require 'test_helper'

class XmlTest < MiniTest::Spec
  Xml = Representable::Xml
  Def = Representable::Definition
  
  describe "Xml module" do
    describe "#binding_for_definition" do
      it "returns AttributeBinding" do
        assert_kind_of Xml::AttributeBinding, Xml.binding_for_definition(Def.new(:band, :from => "@band"))
      end
      
      it "returns ObjectBinding" do
        assert_kind_of Xml::ObjectBinding, Xml.binding_for_definition(Def.new(:band, :as => Hash))
      end
      
      #it "returns NamespaceBinding" do
      #  assert_kind_of Xml::AttributeBinding, Xml.binding_for_definition(Def.new(:band, :from => "@band"))
      #end
      
      it "returns TextBinding" do
        assert_kind_of Xml::TextBinding, Xml.binding_for_definition(Def.new(:band, :from => :content))
      end
    end
  end
end
