require 'active_support'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/array/extract_options'
require 'active_support/core_ext/string/starts_ends_with'
require 'active_support/core_ext/string/inflections.rb'
require 'active_support/core_ext/hash/reverse_merge.rb'

require 'hooks/inheritable_attribute'


require 'representable/definition'
require 'representable/nokogiri_extensions'
require 'representable/references'

require 'representable/xml' # TODO: do that dynamically.

module Representable
  def self.included(base)
    base.class_eval do
      extend  ClassMethods::Accessors, ClassMethods::Declarations
      
      
      attr_accessor :roxml_references
      
      extend Hooks::InheritableAttribute
      inheritable_attr :representable_attrs
      self.representable_attrs = []
      
      inheritable_attr :explicit_representation_name  # FIXME: move to Accessors.
      
      
      extend Xml::Declarations  # DISCUSS: do that dynamically?
      extend Xml::ClassMethods  # DISCUSS: do that dynamically?
      include Xml::InstanceMethods  # DISCUSS: do that dynamically?
    end
  end
  
  module ClassMethods # :nodoc:
    module Declarations
      def definition_class
        Definition
      end
      

      # Declares a reference to a certain xml element, whether an attribute, a node,
      # or a typed collection of nodes.  This method does not add a corresponding accessor
      # to the object.  For that behavior see the similar methods: .xml_reader and .xml_accessor.
      #
      # == Sym Option
      # [sym]   Symbol representing the name of the accessor.
      #
      # === Default naming
      # This name will be the default node or attribute name searched for,
      # if no other is declared.  For example,
      #
      #  xml_reader   :bob
      #  xml_accessor :pony, :from => :attr
      #
      # are equivalent to:
      #
      #  xml_reader   :bob, :from => 'bob'
      #  xml_accessor :pony, :from => '@pony'
      #
      # == Options
      # === :as
      # ==== Basic Types
      # Allows you to specify one of several basic types to return the value as.  For example
      #
      #  xml_reader :count, :as => Integer
      #
      # is equivalent to:
      #
      #  xml_reader(:count) {|val| Integer(val) unless val.empty? }
      #
      # Such block shorthands for Integer, Float, Fixnum, BigDecimal, Date, Time, and DateTime
      # are currently available, but only for non-Hash declarations.
      #
      # To reference many elements, put the desired type in a literal array. e.g.:
      #
      #   xml_reader :counts, :as => [Integer]
      #
      # Even an array of text nodes can be specified with :as => []
      #
      #   xml_reader :quotes, :as => []
      #
      # === Other ROXML Class
      # Declares an accessor that represents another ROXML class as child XML element
      # (one-to-one or composition) or array of child elements (one-to-many or
      # aggregation) of this type. Default is one-to-one. For one-to-many, simply pass the class
      # as the only element in an array.
      #
      # Composition example:
      #  <book>
      #   <publisher>
      #     <name>Pragmatic Bookshelf</name>
      #   </publisher>
      #  </book>
      #
      # Can be mapped using the following code:
      #   class Book
      #     xml_reader :publisher, :as => Publisher
      #   end
      #
      # Aggregation example:
      #  <library>
      #   <books>
      #    <book/>
      #    <book/>
      #   </books>
      #  </library>
      #
      # Can be mapped using the following code:
      #  class Library
      #    xml_reader :books, :as => [Book], :in => "books"
      #  end
      #
      # If you don't have the <books> tag to wrap around the list of <book> tags:
      #  <library>
      #   <name>Ruby books</name>
      #   <book/>
      #   <book/>
      #  </library>
      #
      # You can skip the wrapper argument:
      #    xml_reader :books, :as => [Book]
      #
      # === :from
      # The name by which the xml value will be found, either an attribute or tag name in XML.
      # Default is sym, or the singular form of sym, in the case of arrays and hashes.
      #
      # This value may also include XPath notation.
      #
      # ==== :from => :content
      # When :from is set to :content, this refers to the content of the current node,
      # rather than a sub-node. It is equivalent to :from => '.'
      #
      # Example:
      #  class Contributor
      #    xml_reader :name, :from => :content
      #    xml_reader :role, :from => :attr
      #  end
      #
      # To map:
      #  <contributor role="editor">James Wick</contributor>
      #
      # ==== :from => :attr
      # When :from is set to :attr, this refers to the content of an attribute,
      # rather than a sub-node. It is equivalent to :from => '@attribute_name'
      #
      # Example:
      #  class Book
      #    xml_reader :isbn, :from => "@ISBN"
      #    xml_accessor :title, :from => :attr # :from defaults to '@title'
      #  end
      #
      # To map:
      #  <book ISBN="0974514055" title="Programming Ruby: the pragmatic programmers' guide" />
      #
      # ==== :from => :text
      # The default source, if none is specified, this means the accessor
      # represents a text node from XML.  This is documented for completeness
      # only.  You should just leave this option off when you want the default behavior,
      # as in the examples below.
      #
      # :text is equivalent to :from => accessor_name, and you should specify the
      # actual node name (and, optionally, a namespace) if it differs, as in the case of :author below.
      #
      # Example:
      #  class Book
      #    xml_reader :author, :from => 'Author'
      #    xml_accessor :description, :cdata => true
      #    xml_reader :title
      #  end
      #
      # To map:
      #  <book>
      #   <title>Programming Ruby: the pragmatic programmers' guide</title>
      #   <description><![CDATA[Probably the best Ruby book out there]]></description>
      #   <Author>David Thomas</Author>
      #  </book>
      #
      # Likewise, a number of :text node values can be collected in an array like so:
      #
      # Example:
      #  class Library
      #    xml_reader :books, :as => []
      #  end
      #
      # To map:
      #  <library>
      #      <book>To kill a mockingbird</book>
      #      <book>House of Leaves</book>
      #    <book>Gödel, Escher, Bach</book>
      #  </library>
      #
      # === Other Options
      # [:in] An optional name of a wrapping tag for this XML accessor.
      #       This can include other xpath values, which will be joined with :from with a '/'
      # [:required] If true, throws RequiredElementMissing when the element isn't present
      # [:cdata] true for values which should be input from or output as cdata elements
      # [:to_xml] this proc is applied to the attributes value outputting the instance via #to_xml
      #
      def representable_attr(*syms, &block)
        opts = syms.extract_options!
        syms.map do |sym|
          definition_class.new(sym, opts, &block).tap do |attr|
            representable_attrs << attr
          end
        end
      end

      # Declares a read-only xml reference. See xml_attr for details.
      #
      # Note that while xml_reader does not create a setter for this attribute,
      # its value can be modified indirectly via methods.  For more complete
      # protection, consider the :frozen option.
      def representable_reader(*syms, &block)
        representable_attr(*syms, &block).each do |attr|
          add_reader(attr)
        end
      end

      # Declares a writable xml reference. See xml_attr for details.
      #
      # Note that while xml_accessor does create a setter for this attribute,
      # you can use the :frozen option to prevent its value from being
      # modified indirectly via methods.
      def representable_accessor(*syms, &block)
        representable_attr(*syms, &block).each do |attr|
          add_reader(attr)
          attr_writer(attr.accessor)
        end
      end

    private
      def add_reader(attr)
        define_method(attr.accessor) do
          instance_variable_get(attr.instance_variable_name)
        end
      end
    end

    module Accessors
      def representation_name=(name)
        self.explicit_representation_name = name
      end
      
      def representation_name
        explicit_representation_name or name.split('::').last.underscore
      end
    end
  end
end
