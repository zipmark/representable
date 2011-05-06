require 'representable'
require 'representable/bindings/xml_bindings'

module Representable
  module Xml
    BINDING_FOR_TYPE = {
      :attr     => AttributeBinding,
      :text     => TextBinding,
      :namespace=> NamespaceBinding,
    }
    
    def self.binding_for_definition(definition)
      (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
    end
    
    def self.included(base)
      base.class_eval do
        include Representable
        include Xml::InstanceMethods
        extend Xml::Declarations
        extend Xml::ClassMethods
      end
    end
    
    
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
    
    class Definition < Representable::Definition
      # FIXME: extract xml-specific from Definition.
    end
    
    module ClassMethods
    def definition_class
      Definition
    end
    
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Example:
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      def from_xml(data, *args)
        xml = Nokogiri::XML::Node.from(data)

        create_from_xml(*args).tap do |inst|
          refs = representable_attrs.map {|attr| Xml.binding_for_definition(attr) }
          
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
      # Returns a Nokogiri::XML object representing this object.
      def to_xml(params={})
        params.reverse_merge!(:name => self.class.representation_name)
        
        Nokogiri::XML::Node.new(params[:name].to_s, Nokogiri::XML::Document.new).tap do |root|
          refs = self.class.representable_attrs.map {|attr| Xml.binding_for_definition(attr) }
          
          refs.each do |ref|
            value = public_send(ref.accessor) # DISCUSS: eventually move back to Ref.
            ref.update_xml(root, value) if value
          end
        end
      end
    end
  end # Xml
end
