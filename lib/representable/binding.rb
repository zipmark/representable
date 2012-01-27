module Representable
  class Binding
    attr_reader :definition

    def initialize(definition)
      @definition = definition
    end
    
    # Main entry point for rendering/parsing a property object.
    module Hooks
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
  end
end
