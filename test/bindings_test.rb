require 'test_helper'

class ReferenceTest < MiniTest::Spec
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

class DefinitionTest < MiniTest::Spec
  describe "generic API" do
    before do
      @def = Representable::Definition.new(:songs)
    end
    
    it "responds to #typed?" do
      assert ! @def.typed?
      assert Representable::Definition.new(:songs, :as => Hash).typed?
      assert Representable::Definition.new(:songs, :as => [Hash]).typed?
    end
  end
  
  
  describe "#apply" do
    it "works with a single item" do
      @d = Representable::Definition.new(:song)
      assert_equal 2, @d.apply(1) { |v| v+1 }
    end
    
    it "works with collection" do
      @d = Representable::Definition.new(:song, :as => [])
      assert_equal [2,3,4], @d.apply([1,2,3]) { |v| v+1 }
    end
    
    it "skips with collection and nil" do
      @d = Representable::Definition.new(:song, :as => [])
      assert_equal nil, @d.apply(nil) { |v| v+1 }
    end
  end
    
  describe ":as => []" do
    before do
      @def = Representable::Definition.new(:songs, :as => [], :tag => :song)
    end
    
    it "responds to #accessor" do
      assert_equal "songs", @def.accessor
    end
    
    it "responds to #array?" do
      assert @def.array?
    end
    
    it "responds to #name" do
      assert_equal "songs", @def.accessor 
    end
    
    it "responds to #instance_variable_name" do
      assert_equal :"@songs", @def.instance_variable_name
    end
    
    it "responds to #setter" do
      assert_equal :"songs=", @def.setter
    end
    
    it "responds to #sought_type" do
      assert_equal :text, @def.sought_type
    end
  end
    
    
  describe ":as => [Item]" do
    before do
      @def = Representable::Definition.new(:songs, :as => [Hash])
    end
    
    it "responds to #sought_type" do
      assert_equal Hash, @def.sought_type
    end
  end
  
  
  describe ":as => Item" do
    before do
      @def = Representable::Definition.new(:songs, :as => Hash)
    end
    
    it "responds to #sought_type" do
      assert_equal Hash, @def.sought_type
    end
  end
end
