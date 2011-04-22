module ROXML
  class RequiredElementMissing < Exception # :nodoc:
  end

  # Internal base class that represents an XML - Class binding.
  class XMLRef
    attr_reader :definition
    delegate :required?, :array?, :accessor, :wrapper, :name, :to => :definition

    def initialize(definition, instance)
      @definition = definition
      @instance   = instance  # FIXME: i hate that dependency.
    end
    
    def value_in(xml)
      xml = XML::Node.from(xml) or return default
      
      fetch_value(xml) or default
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
      XML.add_node(xml, wrap_with.to_s)
    end

    def nodes_in(xml)
      vals = xml.roxml_search(xpath, "")  # TODO: handle namespace.
      
      vals = vals.collect do |val|
        yield val
      end
      
      array? ? vals : vals.first  # FIXME: two different classes.
    end
  end

  # Interal class representing an XML attribute binding
  #
  # In context:
  #  <element attribute="XMLAttributeRef">
  #   XMLTextRef
  #  </element>
  class XMLAttributeRef < XMLRef # :nodoc:
    # Updates the attribute in the given XML block to
    # the value provided.
    def update_xml(xml, values)
      wrap(xml).tap do |xml|
        xml[name] = values.to_s
      end
    end

  private
    def fetch_value(xml)
      xml[name]
    end
  end

  # Interal class representing XML content text binding
  #
  # In context:
  #  <element attribute="XMLAttributeRef">
  #   XMLTextRef
  #  </element>
  class XMLTextRef < XMLRef # :nodoc:
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
            add(XML.add_node(xml, name), v)
          end
        else
          add(XML.add_node(xml, name), value)
        end
      end
    end

  private
    def fetch_value(xml)
      nodes_in(xml) do |node| 
        node.content
      end
    end

    def add(dest, value)
      if cdata?
        XML.add_cdata(dest, value.to_s)
      else
        XML.set_content(dest, value.to_s)
      end
    end
  end

  class XMLNameSpaceRef < XMLRef # :nodoc:
    private
      def fetch_value(xml)
        xml.namespace.prefix
      end
  end


  class XMLObjectRef < XMLTextRef # :nodoc:
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
    def fetch_value(xml)
      nodes_in(xml) do |node|
        deserialize(sought_type, node)
      end
    end
    
    def update_xml_for_collection(xml, collection)
      collection.each do |item|
        update_xml_for_entity(xml, item)
      end
    end
    
    def update_xml_for_entity(xml, entity)
      XML.add_child(xml, serialize(entity))
    end
  end
end
