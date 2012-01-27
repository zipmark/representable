require 'representable/binding'

module Representable
  module XML
    module ObjectBiiinding
      include Representable::JSON::Extend  # provides #serialize/#deserialize with extend.
      
      def serialize(object)
        super(object).to_node(:wrap => false)
      end
      
      def deserialize(hash)
        super(create_object).from_node(hash)
      end
      
      def create_object
        definition.sought_type.new
      end
      
      def serialize_for(value, parent)
        serialize(value)
      end
      
      def deserialize_from(node)
        nodes   = node.search("./#{xpath}")
        node = nodes.first  # FIXME.
        deserialize(node)
      end
    end
    
    class Binding < Representable::Binding
      def read(xml)
        value_from_node(xml)
      end
      
      def write(doc, value)
        
      end
      
      
    private
      def xpath
        definition.from
      end

      def collect_for(xml)
        nodes = xml.search("./#{xpath}")
        vals  = nodes.collect { |node| yield node }
        
        definition.array? ? vals : vals.first
      end
    end
    
    class PropertyBinding < Binding
      include JSON::Hooks # FIXME: move to generic layer.
      
      def initialize(definition)
        super
        extend ObjectBiiinding if definition.typed? # FIXME.
      end
      
      def write(parent, value)
        parent << serialize_for(value, parent)
        
      end
      def read(node)
        deserialize_from(node)
      end
      
      
      def serialize_for(value, parent)
        node =  Nokogiri::XML::Node.new(definition.from, parent.document)
        node.content = serialize(value)
        #parent.add_child(serialize_for(value, node))
        node
      end
      
      def deserialize_from(node)
        nodes   = node.search("./#{xpath}")
        content = nodes.first.content
        deserialize(content)
      end
    end
    
    class CollectionBinding < PropertyBinding
      def write(parent, value)
        serialize_for(value, parent).each do |node|
          parent << node
        end
      end
      
      def serialize_for(value, parent)
        Nokogiri::XML::NodeSet.new(parent.document, value.collect { |obj| 
          node=Nokogiri::XML::Node.new(definition.from, parent.document)
          node.content = serialize(obj);node })
      end
      
      def deserialize_from(fragment)
        nodes = fragment.search("./#{xpath}")
        nodes.collect { |node| deserialize(node.content) }
      end
    end
    
    class HashBinding < CollectionBinding
      def serialize_for(value, parent)
        document = parent.document
        Nokogiri::XML::NodeSet.new(document, value.collect { |k, v|
        
          node = Nokogiri::XML::Node.new(k, document)
        
          node.content = serialize(v);
          node })
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
    
    
    # Represents text content in a tag. # FIXME: is this tested???
    class TextBinding < Binding
      def write(xml, value)
        if definition.array?
          value.each do |v|
            add(xml, definition.from, v)
          end
        else
          add(xml, definition.from, value)
        end
      end

    private
      def value_from_node(xml)
        collect_for(xml) do |node| 
          node.content
        end
      end
      
      def add(xml, name, value)
        child = xml.add_child Nokogiri::XML::Node.new(name, xml.document)
        child.content = value
      end
    end
    

    # Represents a tag with object binding.
    class ObjectBinding < Binding
      include Representable::Binding::Hooks # includes #create_object and #write_object.
      include Representable::Binding::Extend
      
      # Adds the ref's markup to +xml+. 
      def write(xml, object)
        if definition.array?
          object.each do |item|
            write_entity(xml, item)
          end
        else
          write_entity(xml, object)
        end
      end

    private
      # Deserializes the ref's element from +xml+.
      def value_from_node(xml)
        collect_for(xml) do |node|
          create_object.from_node(node)
        end
      end
      
      def write_entity(xml, entity)
        xml.add_child(write_object(entity).to_node)
      end
    end
  end
end
