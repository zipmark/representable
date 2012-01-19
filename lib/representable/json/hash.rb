module Representable::JSON
  module Hash
    include Representable::JSON
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end
    
    
    module ClassMethods
      def items(options)  # FIXME: 
        collection :_self, options
      end
    end
    
    
    def create_representation_with(doc, options, format)
      bin   = representable_bindings_for(format).first
      value = find_all { true }
      bin.write(doc, value)
    end
    
    def update_properties_from(doc, options, format)
      bin   = representable_bindings_for(format).first
      value = bin.read(bin.definition.from => doc)
      replace(value)
    end
    
    # FIXME: refactor Definition so we can simply add options in #items to existing definition.
    def representable_attrs
      attrs = super
      attrs << Definition.new(:_self, :collection => true) if attrs.size == 0
      attrs
    end
  end
end
