module ROXML
  class RequiredElementMissing < Exception # :nodoc:
  end

  # Internal base class that represents an XML - Class binding.
  class XMLRef
    attr_reader :opts
    delegate :required?, :array?, :accessor, :default, :wrapper, :name, :to => :opts

    def initialize(definition, instance)
      @opts = definition
      @instance = instance  # FIXME: i hate that dependency.
    end

    def to_xml(instance)
      val = instance.public_send(accessor)
      opts.to_xml.respond_to?(:call) ? opts.to_xml.call(val) : val
    end

    def value_in(xml)
      xml = XML::Node.from(xml)
      value = fetch_value(xml)
    end

  private

    def xpath
      return "contributor" if name == "contributors"  # FIXME: haha.
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
      puts "getting nodes from #{self.name}"
      vals = xml.roxml_search(xpath, @instance.class.roxml_namespaces)
      
      if vals.empty?
        ""#default
      elsif array?
        vals.map do |val|
          puts "yielding #{val.inspect}"
          yield val
        end
      else
        yield(vals.first)
      end
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
      if array?
        values.each do |value|
          wrap(xml, :always_create => true).tap do |node|
            XML.set_attribute(node, name, value.to_s)
          end
        end
      else
        wrap(xml).tap do |xml|
          XML.set_attribute(xml, name, values.to_s)
        end
      end
    end

  private
    def fetch_value(xml)
      nodes_in(xml) do |node|
        node.value
      end
    end

    def xpath_name
      "@#{name}"
    end
  end

  # Interal class representing XML content text binding
  #
  # In context:
  #  <element attribute="XMLAttributeRef">
  #   XMLTextRef
  #  </element>
  class XMLTextRef < XMLRef # :nodoc:
    delegate :cdata?, :content?, :name?, :to => :opts

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
    delegate :sought_type, :to => :opts

    # Updates the composed XML object in the given XML block to
    # the value provided.
    def update_xml(xml, value)
      wrap(xml).tap do |xml|
        params = {:name => name, :namespace => opts.namespace}
        if array?
          value.each do |v|
            XML.add_child(xml, v.to_xml(params))
          end
        elsif value.is_a?(ROXML)
          XML.add_child(xml, value.to_xml(params))
        else
          XML.add_node(xml, name).tap do |node|
            XML.set_content(node, value.to_xml)
          end
        end
      end
    end

  private
    def fetch_value(xml)
      nodes_in(xml) do |node|
        sought_type.from_xml(node)
      end
    end
  end
end
