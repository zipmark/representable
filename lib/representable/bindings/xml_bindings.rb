require 'representable/binding'
require 'representable/bindings/json_bindings'  # FIXME.

module Representable
  module XML
    module ObjectBinding
      include Representable::JSON::Extend  # provides #serialize/#deserialize with extend.
      
      def serialize(object)
        super(object).to_node(:wrap => false)
      end
      
      def deserialize_node(node)
        deserialize(node)
      end
      def serialize_node(node, value)
        obj=serialize(value)
        puts "seraial #{obj.inspect}"
        obj
      end
      
      def deserialize(hash)
        super(create_object).from_node(hash)
      end
      
      def create_object
        definition.sought_type.new
      end
    end
    
    class Binding < Representable::Binding
    private
      def xpath
        definition.from
      end
    end
    
    class PropertyBinding < Binding
      include JSON::Hooks # FIXME: move to generic layer.
      
      def initialize(definition)
        super
        extend ObjectBinding if definition.typed? # FIXME.
      end
      
      def write(parent, value)
        parent << serialize_for(value, parent)
        
      end
      def read(node)
        deserialize_from(node)
      end
      
      
      #def serialize_for(value, parent, tag_name=definition.from)
      def serialize_for(value, parent)
        node =  Nokogiri::XML::Node.new(definition.from, parent.document)
        serialize_node(node, value)
      end
      
      def serialize_node(node, value)
        node.content = serialize(value)
        node
      end
      
      
      def deserialize_from(node)
        nodes   = node.search("./#{xpath}")
        return if nodes.size == 0 # TODO: write dedicated test!
        
        deserialize_node(nodes.first)
      end
      
      def deserialize_node(node)
        deserialize(node.content)
      end
    end
    
    class CollectionBinding < PropertyBinding
      def write(parent, value)
        serialize_list(value, parent).each do |node|
          parent << node
        end
      end
      
      def serialize_list(value, parent)
        Nokogiri::XML::NodeSet.new(parent.document, value.collect { |obj| 
          serialize_for(obj, parent)
          #node = Nokogiri::XML::Node.new(definition.from, parent.document)
          #node.content = serialize_node(parent, obj);
           })
      end
      
      def deserialize_from(fragment)
        property_nodes = fragment.search("./#{xpath}")
        
        property_nodes.collect do |item|
          deserialize_node(item)
        end
      end
    end
    
    class HashBinding < CollectionBinding
      def serialize_list(value, parent)
        document = parent.document
        Nokogiri::XML::NodeSet.new(document, value.collect { |k, v|
        
          node = Nokogiri::XML::Node.new(k, document)
          serialize_node(node, v);
          
           })
      end
      
      def deserialize_from(fragment)
        {}.tap do |hash|
          fragment.search("./#{xpath}").children.each do |node|
            hash[node.name] = deserialize(node.content)
          end
        end
      end
    end
    
    
    # Represents a tag attribute. Currently this only works on the top-level tag.
    class AttributeBinding < PropertyBinding
      def deserialize_from(fragment)
        deserialize(fragment[definition.from])
      end
      
      def serialize_for(value, parent)
        parent[definition.from] = serialize(value.to_s)
      end
      
      def write(parent, value)
        serialize_for(value, parent)
        
        
      end
    end
  end
end
