require 'spec_helper'

require 'test_xml/spec'

describe ROXML, "#xml" do
  class Contributor
    include ROXML

    xml_accessor :role, :from => :attr
    xml_accessor :name
  end
  
  class Band
    include ROXML
    xml_accessor :name
  end
  
  class Label
    def to_xml
      "<label>Fat Wreck</label>"
    end
  end
    
  
  describe "generic tests" do
    context ".from_xml" do
      it "works with empty string" do
        album = Album.from_xml("")
        album.band.should == []
      end
    end
  end
  
  
  describe ":from => @rel" do
    class Link
      include ROXML
      xml_accessor :href,   :from => "@href"
      xml_accessor :title,  :from => "@title"
    end
    
    context ".from_xml" do
      it "creates correct accessors" do
        link = Link.from_xml(%{
          <a href="http://apotomo.de" title="Home, sweet home" />
        })
        link.href.should == "http://apotomo.de"
        link.title.should == "Home, sweet home"
      end
    end
    
    context "#to_xml" do
      it "serializes correctly" do
        link = Link.new
        link.href = "http://apotomo.de/"
        
        link.to_xml.to_s.should exactly_match_xml %{<link href="http://apotomo.de/">}
      end
    end
  end
  
  
  describe ":as => Item" do
    class Album
      include ROXML
      xml_accessor :band, :as => Band
      xml_accessor :label, :as => Label
    end
    
    context ".from_xml" do
      it "creates one Item instance" do
        album = Album.from_xml(%{
          <album>
            <band><name>Bad Religion</name></band>
          </album>
        })
        album.band.name.should == "Bad Religion"
      end
    end
    
    context "#to_xml" do
      it "doesn't escape xml from Band#to_xml" do
        band = Band.new
        band.name = "Bad Religion"
        album = Album.new
        album.band = band
        
        album.to_xml.to_s.should exactly_match_xml %{<album>
         <band>
           <name>Bad Religion</name>
         </band>
       </album>}
      end
      
      it "doesn't escape string from Label#to_xml" do
        album = Album.new
        album.label = Label.new
        
        album.to_xml.to_s.should exactly_match_xml %{<album>
          <label>Fat Wreck</label>
        </album>}
      end
    end
  end
  

  describe "collections" do
    context ":as => [Item]" do
      class Book
        include ROXML


        xml_accessor :contributors, :as => [Contributor], :tag => :contributor
      end

      it ".from_xml pushes collection items to array" do
        book = Book.from_xml(%{
          <book>
            <contributor><name>David Thomas</name></contributor>
            <contributor><name>Andrew Hunt</name></contributor>
            <contributor><name>Chad Fowler</name></contributor>
          </book>
        })
        book.contributors.map(&:name).sort.should == ["David Thomas","Andrew Hunt","Chad Fowler"].sort
      end
      
      it "collections can be empty" do
        book = Book.from_xml(%{
          <book>
          </book>
        })
        book.contributors.should == []
      end
      
      it "responds to #to_xml" do
        book = Book.new
        david = Contributor.new
        david.name= "David Thomas"
        chad = Contributor.new
        chad.name= "Chad Fowler"
        book.contributors = [david, chad]
        
        book.to_xml.to_s.should exactly_match_xml %{<book>
            <contributor><name>David Thomas</name></contributor>
            <contributor><name>Chad Fowler</name></contributor>
          </book>}
      end
    end
    
    
    context ":as => []" do
      class Album
        include ROXML
        
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
        album.songs.sort.should == ["Laundry Basket", "Two Kevins", "Wright and Rong"].sort
      end
    end
  end
  
  def parse_xml(xml); ROXML::XML::Node.from(xml); end
  
  describe "Reference" do
    context "ObjectRef with []" do
      subject do
        ROXML::XMLObjectRef.new(ROXML::Definition.new(:songs, :as => [Album]), nil)
      end
      
      it "responds to #default" do
        subject.send(:default).should == []
      end
      
    end
    
    
    context "TextRef#value_in" do
      subject do
        ROXML::XMLTextRef.new(ROXML::Definition.new(:song), nil)
      end
      
      it "returns found value" do
        subject.value_in(parse_xml("<a><song>Unkoil</song></a>")).should == "Unkoil"
      end
      
    end
  end    
  
  
  describe "Definition" do
    context ":as => []" do
      subject do
        ROXML::Definition.new(:songs, :as => [], :tag => :song)
      end
      
      it "responds to #accessor" do
        subject.accessor.should == "songs"
      end
      
      it "responds to #array?" do
        subject.array?.should be_true
      end
      
      it "responds to #name" do
        subject.accessor.should == "songs"
      end
      
      it "responds to #instance_variable_name" do
        subject.instance_variable_name.should == :"@songs"
      end
      
      it "responds to #setter" do
        subject.setter.should == :"songs="
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == :text
      end
    end
    
    
    context ":as => [Item]" do
      subject do
        class Song; end
        ROXML::Definition.new(:songs, :as => [Song])
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == Song
      end
    end
    
    
    context ":as => Item" do
      subject do
        class Song; end
        ROXML::Definition.new(:songs, :as => Song)
      end
      
      it "responds to #sought_type" do
        subject.sought_type.should == Song
      end
    end
  end
end
