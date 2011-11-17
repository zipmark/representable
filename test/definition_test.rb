require 'test_helper'

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
    
    it "responds to #getter and returns string" do
      assert_equal "songs", @def.getter
    end
    
    it "responds to #name" do
      assert_equal "songs", @def.name 
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
    
    it "responds to #array?" do
      assert @def.array?
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
