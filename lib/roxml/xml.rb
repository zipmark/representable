module ROXML
  module Xml
    module Declarations
      # Sets the name of the XML element that represents this class. Use this
      # to override the default lowercase class name.
      #
      # Example:
      #  class BookWithPublisher
      #   xml_name :book
      #  end
      #
      # Without the xml_name annotation, the XML mapped tag would have been "bookwithpublisher".
      def xml_name(name)
        self.explicit_representation_name = name
      end
      
      def xml_accessor(*args) # TODO: remove me, just for back-compat.
        representable_accessor(*args)
      end
      
    end
    
    module ClassMethods
      #
      # Creates a new Ruby object from XML using mapping information
      # annotated in the class.
      #
      # The input data is either an XML::Node, String, Pathname, or File representing
      # the XML document.
      #
      # Example
      #  book = Book.from_xml(File.read("book.xml"))
      # or
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      #
      # _initialization_args_ passed into from_xml will be passed into
      # the object's .new, prior to populating the xml_attrs.
      #
      # After the instatiation and xml population
      #
      # See also: xml_initialize
      #
      def from_xml(data, *args)
        xml = Nokogiri::XML::Node.from(data)

        create_from_xml(*args).tap do |inst|
          refs = representable_attrs.map {|attr| attr.to_ref }
          
          refs.each do |ref|
            value = ref.value_in(xml)
            
            inst.send(ref.definition.setter, value)
          end
        end
      end
      
    private
      def create_from_xml(*args)
        new(*args)
      end
    end
    
    module InstanceMethods # :nodoc:
      # Returns an XML object representing this object
      def to_xml(params={})
        params.reverse_merge!(:name => self.class.representation_name)
        
        Nokogiri::XML::Node.new(params[:name].to_s, Nokogiri::XML::Document.new).tap do |root|
          refs = self.class.representable_attrs.map {|attr| attr.to_ref }
          
          refs.each do |ref|
            value = public_send(ref.accessor) # DISCUSS: eventually move back to Ref.
            ref.update_xml(root, value) if value
          end
        end
      end
    end
  end # Xml
end
