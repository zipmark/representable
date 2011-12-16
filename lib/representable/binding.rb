module Representable
  class Binding
    attr_reader :definition

    def initialize(definition)
      @definition = definition
    end
    
    
    # Usually called in concrete ObjectBinding in #write and #read. 
    module Hooks
    private
      # Must be called in serialization of concrete ObjectBinding.
      def write_object(object)
        object
      end
      
      # Creates a typed property instance.
      def create_object
        definition.sought_type.new
      end
    end
    
    
    # Hooks into #write_object and #create_object to extend typed properties
    # at runtime.
    module Extend
    private
      # Extends the object with its representer before serialization.
      def write_object(object)
        extend_for(super)
      end
      
      def create_object
        extend_for(super)
      end
      
      def extend_for(object)  # TODO: test me.
        if mod = definition.representer_module
          object.extend(mod)
        end
        
        object
      end
    end
  end
end
