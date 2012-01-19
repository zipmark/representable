require 'representable/binding'

module Representable
  module JSON
    module Hooks
    private
      def serialize(value)
        value
      end
      
      def deserialize(fragment)
        fragment
      end
    end
    
    # Hooks into #serialize and #deserialize to extend typed properties
    # at runtime.
    module Extend
    private
      # Extends the object with its representer before serialization.
      def serialize(object)
        extend_for(super)
      end
      
      def deserialize(*)
        extend_for(super)
      end
      
      def extend_for(object)
        if mod = definition.representer_module
          object.extend(*mod)
        end
        
        object
      end
    end
    
    module ObjectBindiiing
      include Representable::JSON::Extend  # provides #serialize/#deserialize with extend.
      
      def serialize(object)
        super(object).to_hash(:wrap => false)
      end
      
      def deserialize(hash)
        super(create_object).from_hash(hash)
      end
      
      def create_object
        definition.sought_type.new
      end
    end
    
    class PropertyBinding < Representable::Binding
      include Representable::JSON::Hooks
      
      def initialize(definition)
        super
        extend ObjectBindiiing if definition.typed? # FIXME.
      end
      
      def write(hash, value)
        hash[definition.from] = serialize(value)
      end
      
      def read(hash)
        fragment = hash[definition.from]
        deserialize(fragment)
      end
      
      include Hooks
    end
    
    
    class Binding < Representable::Binding
    private
      def collect_for(hash)
        nodes = hash[definition.from] or return
        nodes = [nodes] unless nodes.is_a?(Array)
        
        vals  = nodes.collect { |node| yield node }
        
        definition.array? ? vals : vals.first
      end
    end
    
    # Represents plain key-value.
    class TextBinding < Binding
      def write(hash, value)
        hash[definition.from] = value
      end
      
      def read(hash)
        collect_for(hash) do |value|
          value
        end
      end
    end
  
    # Represents a tag with object binding.
    class ObjectBinding < Binding
      include Representable::Binding::Hooks # includes #create_object and #write_object.
      include Representable::Binding::Extend
      
      def write(hash, object)
        if definition.array?
          hash[definition.from] = object.collect { |obj| serialize(obj) }
        else
          hash[definition.from] = serialize(object)
        end
      end
      
      def read(hash)
        collect_for(hash) do |node|
          create_object.from_hash(node)
        end
      end
      
    private
      def serialize(object)
        write_object(object).to_hash(:wrap => false)
      end
    end
  end
end
