require 'representable/definition'

module Representable
  def self.included(base)
    base.class_eval do
      extend ClassMethods::Declarations
      extend ClassMethods::Accessors
      
      def self.included(base)
        base.representable_attrs.push(*representable_attrs) # "inherit".
      end
    end
  end
  
  # Reads values from +doc+ and sets properties accordingly.
  def update_properties_from(doc, &block)
    self.class.representable_bindings.each do |bin|
      next if eval_property_block(bin, &block)  # skip if block is false.
      
      value = bin.read(doc) || bin.definition.default
      send(bin.definition.setter, value)
    end
    self
  end
  
private
  # Compiles the document going through all properties.
  def create_representation_with(doc, &block)
    self.class.representable_bindings.each do |bin|
      next if eval_property_block(bin, &block)  # skip if block is false.
      
      value = send(bin.definition.getter) || bin.definition.default # DISCUSS: eventually move back to Ref.
      bin.write(doc, value) if value
    end
    doc
  end
  
  # Returns true unless a eventually given block returns false. Yields the symbolized
  # property name.
  def eval_property_block(binding)
    # TODO: no magic symbol conversion!
    block_given? and not yield binding.definition.name.to_sym
  end
  
  
  module ClassMethods # :nodoc:
    module Declarations
      def definition_class
        Definition
      end
      
      # Returns bindings for all properties.
      def representable_bindings
        representable_attrs.map {|attr| binding_for_definition(attr) }
      end
      
      # Declares a represented document node, which is usually a XML tag or a JSON key.
      #
      # Examples:
      #
      #   representable_property :name
      #   representable_property :name, :from => :title
      #   representable_property :name, :as => Name
      #   representable_property :name, :accessors => false
      #   representable_property :name, :default => "Mike"
      def representable_property(name, options={})
        attr = add_representable_property(name, options)
        
        attr_reader(attr.getter) unless options[:accessors] == false
        attr_writer(attr.getter) unless options[:accessors] == false
      end
      
      # Declares a represented document node collection.
      #
      # Examples:
      #
      #   representable_collection :products
      #   representable_collection :products, :from => :item
      #   representable_collection :products, :as => Product
      def representable_collection(name, options={})
        options[:collection] = true
        representable_property(name, options)
      end
      
    private
      def add_representable_property(*args)
        definition_class.new(*args).tap do |attr|
          representable_attrs << attr
        end
      end
    end

    module Accessors
      def representable_attrs
        @representable_attrs ||= []
      end
      
      def representable_wrap
        @representable_wrap ||= false
      end
      
      def representable_wrap=(name)
        @representable_wrap = name
      end
      
      def representation_wrap=(name)
        self.representable_wrap = name
      end
      
      # Returns the wrapper for the representation. Mostly used in XML.
      def representation_wrap
        return unless representable_wrap
        return infer_representation_name if representable_wrap === true
        representable_wrap
      end
      
    private
      def infer_representation_name
        name.split('::').last.
         gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
         gsub(/([a-z\d])([A-Z])/,'\1_\2').
         downcase
      end
    end
  end
end
