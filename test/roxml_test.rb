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


class AttributesTest < MiniTest::Spec
  describe ":from => @rel" do
    class Link
      include Representable
      xml_accessor :href,   :from => "@href"
      xml_accessor :title,  :from => "@title"
    end
    
    it "#from_xml creates correct accessors" do
      link = Link.from_xml(%{
        <a href="http://apotomo.de" title="Home, sweet home" />
      })
      assert_equal "http://apotomo.de", link.href
      assert_equal "Home, sweet home",  link.title
    end
  
    it "#to_xml serializes correctly" do
      link = Link.new
      link.href = "http://apotomo.de/"
      
      assert_xml_equal %{<link href="http://apotomo.de/">}, link.to_xml.to_s
    end
  end
end

class TypedPropertyTest < MiniTest::Spec
  describe ":as => Item" do
    class Album
      include Representable
      xml_accessor :band, :as => Band
      xml_accessor :label, :as => Label
    end
    
    it "#from_xml creates one Item instance" do
      album = Album.from_xml(%{
        <album>
          <band><name>Bad Religion</name></band>
        </album>
      })
      assert_equal "Bad Religion", album.band.name
    end
    
    describe "#to_xml" do
      it "doesn't escape xml from Band#to_xml" do
        band = Band.new
        band.name = "Bad Religion"
        album = Album.new
        album.band = band
        
        assert_xml_equal %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}, album.to_xml.to_s
      end
      
      it "doesn't escape and wrap string from Label#to_xml" do
        album = Album.new
        album.label = Label.new
        
        assert_xml_equal %{<album>
          <label>Fat Wreck</label>
        </album>}, album.to_xml.to_s
      end
    end
  end
end


class CollectionTest < MiniTest::Spec
  describe ":as => [Band], :tag => :band" do
    class Compilation
      include Representable
      xml_accessor :bands, :as => [Band], :tag => :band
    end
    
    describe "#from_xml" do
      it "pushes collection items to array" do
        cd = Compilation.from_xml(%{
          <compilation>
            <band><name>Diesel Boy</name></band>
            <band><name>Cobra Skulls</name></band>
          </compilation>
        })
        assert_equal ["Cobra Skulls", "Diesel Boy"], cd.bands.map(&:name).sort
      end
      
      it "collections can be empty" do
        cd = Compilation.from_xml(%{
          <compilation>
          </compilation>
        })
        assert_equal [], cd.bands
      end
    end
    
    it "responds to #to_xml" do
      cd = Compilation.new
      cd.bands = [Band.new("Diesel Boy"), Band.new("Bad Religion")]
      
      assert_xml_equal %{<compilation>
        <band><name>Diesel Boy</name></band>
        <band><name>Bad Religion</name></band>
      </compilation>}, cd.to_xml.to_s
    end
  end
    
    
  describe ":as => []" do
    class Album
      include Representable
      xml_accessor :songs, :as => [], :tag => :song
    end

    it "collects untyped items" do
      album = Album.from_xml(%{
        <album>
          <song>Two Kevins</song>
          <song>Wright and Rong</song>
          <song>Laundry Basket</song>
        </album>
      })
      assert_equal ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort, album.songs.sort
    end
  end
end
