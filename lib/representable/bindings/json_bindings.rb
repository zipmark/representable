require 'representable/binding'

module Representable
  module JSON
    class Binding < Representable::Binding
    private
      def collect_for(hash)
        nodes = hash[definition.from] or return
        nodes = [nodes] unless nodes.is_a?(Array)
        
        vals  = nodes.collect { |node| yield node }
        
        definition.array? ? vals : vals.first
      end
      
      # DISCUSS: include DCI per default?
      include Representable::Binding::Hooks
      include Representable::Binding::DCI
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
      def write(hash, value)
        if definition.array?
          hash[definition.from] = value.collect { |v| serialize(v) }
        else
          hash[definition.from] = serialize(value)
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
