require_relative './spec_helper'

describe ROXML, "#xml" do
  class Contributor
    include ROXML

    xml_reader :role, :from => :attr
    xml_reader :name
  end



  describe "array reference" do
    context "no elements are present in root, no :in is specified" do
      class BookWithContributors
        include ROXML

        xml_name :book
        xml_reader :isbn, :from => :attr
        xml_reader :title
        xml_reader :description
        xml_reader :contributors, :as => [Contributor]
      end

      it "should look for elements :in the plural of name" do
        book = BookWithContributors.from_xml(%{
          <book isbn="0974514055">

              <contributor role="author"><name>David Thomas</name></contributor>
              <contributor role="supporting author"><name>Andrew Hunt</name></contributor>
              <contributor role="supporting author"><name>Chad Fowler</name></contributor>

          </book>
        })
        #puts book.contributors.first.inspect
        book.contributors.map(&:name).sort.should == ["David Thomas","Andrew Hunt","Chad Fowler"].sort
      end
    end
  end
end
