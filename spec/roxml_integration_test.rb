require_relative './spec_helper'

describe ROXML, "#xml" do
  class Contributor
    include ROXML

    xml_reader :role, :from => :attr
    xml_accessor :name
  end



  describe "collections" do
    context ":as => [Item]" do
      class Book
        include ROXML

        xml_name :book
        xml_reader :isbn, :from => :attr
        xml_accessor :contributors, :as => [Contributor], :tag => :contributor
        
        #def contributors=(list)
        #  @contributors = list
        #end
        
      end

      it ".from_xml should push collection items to array" do
        book = Book.from_xml(%{
          <book isbn="0974514055">
            <contributor role="author"><name>David Thomas</name></contributor>
            <contributor role="supporting author"><name>Andrew Hunt</name></contributor>
            <contributor role="supporting author"><name>Chad Fowler</name></contributor>
          </book>
        })
        puts book.inspect
        book.contributors.map(&:name).sort.should == ["David Thomas","Andrew Hunt","Chad Fowler"].sort
      end
      
      it "" do
        book = Book.new
        david = Contributor.new
        david.name= "David Thomas"
        chad = Contributor.new
        chad.name= "Chad Fowler"
        book.contributors = [david, chad]
        
        puts "#{book.inspect}"
        puts book.contributors.inspect
        
        book.to_xml.to_s.should == ROXML::XML.parse_string(%{<book isbn="0974514055">
            <contributor role="author"><name>David Thomas</name></contributor>
            <contributor role="supporting author"><name>Chad Fowler</name></contributor>
          </book>}).root.to_s
      end
    end
    
    
    context ":as => []" do
      class Album
        include ROXML
        
        xml_reader :songs, :as => [], :tag => :song
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
  
  
  
  
  
  
  describe "Definition" do
    context ":as => [Item]" do
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
    end
  end
end
