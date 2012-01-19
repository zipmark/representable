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
    
    
    module ObjectBinding
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
    
    
    class JSONBinding < Representable::Binding
      include Representable::JSON::Hooks
      
      def initialize(definition)
        super
        extend ObjectBinding if definition.typed? # FIXME.
      end
      
      def read(hash)
        fragment = hash[definition.from]
        deserialize_from(fragment)
      end
      
      def write(hash, value)
        hash[definition.from] = serialize_for(value)
      end
    end
    
    
    class PropertyBinding < JSONBinding
      def serialize_for(value)
        serialize(value)
      end
      
      def deserialize_from(fragment)
        deserialize(fragment)
      end
    end
    
    
    class CollectionBinding < JSONBinding
      def serialize_for(value)
        value.collect { |obj| serialize(obj) }
      end
      
      def deserialize_from(fragment)
        fragment ||= {}
        fragment.collect { |item_fragment| deserialize(item_fragment) }
      end
    end
    
    
    class HashBinding < JSONBinding
      def serialize_for(value)
        value.each { |key, obj| value[key] = serialize(obj) }
      end
      
      def deserialize_from(fragment)
        fragment.each { |key, item_fragment| fragment[key] = deserialize(item_fragment) }
      end
    end
  end
end
