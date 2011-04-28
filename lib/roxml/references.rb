module ROXML
  class RequiredElementMissing < Exception # :nodoc:
  end

  # Internal base class that represents an XML - Class binding.
  class XMLRef
    attr_reader :definition
    delegate :required?, :array?, :accessor, :wrapper, :name, :to => :definition

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
      name
    end

    def wrap(xml, opts = {:always_create => false})
      wrap_with = @auto_vals ? auto_wrapper : wrapper

      return xml if !wrap_with || xml.name == wrap_with
      if !opts[:always_create] && (child = xml.children.find {|c| c.name == wrap_with })
       return child
      end
      xml.add_node(wrap_with.to_s)
    end

    def collect_for(xml)
      nodes = xml.search("./#{xpath}")
      vals  = nodes.collect { |node| yield node }
      
      array? ? vals : vals.first
    end
  end
  
  # Represents a tag attribute.
  class XMLAttributeRef < XMLRef
    # Updates the attribute in the given XML block to
    # the value provided.
    def update_xml(xml, values)
      wrap(xml).tap do |xml|
        xml[name] = values.to_s
      end
    end

  private
    def value_from_node(xml)
      xml[name]
    end
  end
  
  # Represents text content in a tag.
  class XMLTextRef < XMLRef
    delegate :cdata?, :content?, :name?, :to => :definition

    # Updates the text in the given _xml_ block to
    # the _value_ provided.
    def update_xml(xml, value)
      wrap(xml).tap do |xml|
        if content?
          add(xml, value)
        elsif name?
          xml.name = value
        elsif array?
          value.each do |v|
            add(xml.add_node(name), v)
          end
        else
          add(xml.add_node(name), value)
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
      if cdata?
        dest.add_child(Nokogiri::XML::CDATA.new(dest.document, content))
      else
        dest.content = value.to_s
      end
    end
  end

  class XMLNameSpaceRef < XMLRef
    private
      def value_from_node(xml)
        xml.namespace.prefix
      end
  end

  # Represents a tag with object binding.
  class XMLObjectRef < XMLTextRef
    delegate :sought_type, :to => :definition

    # Adds the ref's markup to +xml+. 
    def update_xml(xml, value)
      wrap(xml).tap do |xml|
        if array?
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
        deserialize(sought_type, node)
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
