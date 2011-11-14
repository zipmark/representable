module Representable
  module JSON
    class Binding
      attr_reader :definition
      #delegate :required?, :array?, :accessor, :from, :to => :definition

      def initialize(definition)
        @definition = definition
      end
      
      def read(hash)
        value_from_hash(hash) or default
      end
      
    private
      def default
        ""
      end
      
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

    private
      def value_from_hash(hash)
        collect_for(hash) do |value|
          value
        end
      end
    end
  
    # Represents a tag with object binding.
    class ObjectBinding < Binding
      def write(hash, value)
        if definition.array?
          hash.merge! ({definition.from => value.collect {|v| v.to_hash(:wrap => false)}}) # hier name=> wech.
        else
          hash.merge! value.to_hash
        end
      end

    private
      def default
        []
      end
      
      def value_from_hash(xml)
        collect_for(xml) do |node|
          definition.sought_type.from_json(node, :wrap => false) # hier name=> wech.
        end
      end
      
    end
  end
end
