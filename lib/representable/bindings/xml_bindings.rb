module Representable
  module XML
    class Binding
      attr_reader :definition

      def initialize(definition)
        @definition = definition
      end
      
      def value_in(xml)
        xml = Nokogiri::XML::Node.from(xml) or return default
        
        value_from_node(xml) or default
      end
      
    private
      def default
        ""
      end
      
      def xpath
        definition.from
      end

      def wrap(xml, opts = {:always_create => false})
        wrap_with = @auto_vals ? auto_wrapper : definition.wrapper

        return xml if !wrap_with || xml.name == wrap_with
        if !opts[:always_create] && (child = xml.children.find {|c| c.name == wrap_with })
         return child
        end
        xml.add_node(wrap_with.to_s)
      end

      def collect_for(xml)
        nodes = xml.search("./#{xpath}")
        vals  = nodes.collect { |node| yield node }
        
        definition.array? ? vals : vals.first
      end
    end
    
    
    # Represents a tag attribute.
    class AttributeBinding < Binding
      def update_xml(xml, values)
        wrap(xml).tap do |xml|
          xml[definition.from] = values.to_s
        end
      end

    private
      def value_from_node(xml)
        xml[definition.from]
      end
    end
    
    
    # Represents text content in a tag. # FIXME: is this tested???
    class TextBinding < Binding
      # Updates the text in the given _xml_ block to
      # the _value_ provided.
      def update_xml(xml, value)
        wrap(xml).tap do |xml|
          if definition.content?
            add(xml, value)
          elsif definition.name?
            xml.name = value
          elsif definition.array?
            value.each do |v|
              add(xml.add_node(definition.from), v)
            end
          else
            add(xml.add_node(definition.from), value)
          end
        end
      end

    private
      def value_from_node(xml)
        collect_for(xml) do |node| 
          node.content
        end
      end

      def add(dest, value)
        dest.content = value.to_s
      end
    end
    

    # Represents a tag with object binding.
    class ObjectBinding < Binding
      # Adds the ref's markup to +xml+. 
      def update_xml(xml, value)
        wrap(xml).tap do |xml|
          if definition.array?
            update_xml_for_collection(xml, value)
          else
            update_xml_for_entity(xml, value)
          end
        end
      end

    private
      def default
        []
      end
      
      def serialize(object)
        object.to_xml
      end
      
      def deserialize(node_class, xml)
        node_class.from_xml(xml)
      end
      
      # Deserializes the ref's element from +xml+.
      def value_from_node(xml)
        collect_for(xml) do |node|
          deserialize(definition.sought_type, node)
        end
      end
      
      def update_xml_for_collection(xml, collection)
        collection.each do |item|
          update_xml_for_entity(xml, item)
        end
      end
      
      def update_xml_for_entity(xml, entity)
        xml.add_child(serialize(entity))
      end
    end
  end
end
