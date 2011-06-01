require 'json'
require 'representable/bindings/json_bindings'

module Representable
  module JSON
    BINDING_FOR_TYPE = {  # TODO: refactor #representable_accessor for better extendability.
      :text     => TextBinding,
    }
    def self.binding_for_definition(definition)
      (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
    end
    
    def self.included(base)
      base.class_eval do
        include Representable
        include InstanceMethods
      end
      base.extend ClassMethods  # DISCUSS: do that dynamically?
    end
    
    module ClassMethods
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Example:
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      def from_json(data, options={})
        # DISCUSS: extract #from_json call in Bindings to this place.
        data = ::JSON[data] if data.is_a?(String) # DISCUSS: #from_json sometimes receives a string (in nestings).
        data ||= {}
        
        data = data[representation_name] unless options[:wrap] == false
        
        create_from_json.tap do |inst|
          refs = representable_attrs.map {|attr| JSON.binding_for_definition(attr) }
          
          refs.each do |ref|
            value = ref.value_in(data)
            
            inst.send(ref.definition.setter, value)
          end
        end
      end
      
    private
      def create_from_json(*args)
        new(*args)
      end
    end
    
    module InstanceMethods # :nodoc:
      def to_hash(options={})
        hash = {}.tap do |root|
          refs = self.class.representable_attrs.map {|attr| JSON.binding_for_definition(attr) }
          
          refs.each do |ref|
            value = public_send(ref.accessor) # DISCUSS: eventually move back to Ref.
            ref.update_json(root, value) if value
          end
        end
        
        # DISCUSS: where to wrap?
        options[:wrap] == false ? hash : {self.class.representation_name => hash}
      end
      
      # Returns a Nokogiri::XML object representing this object.
      def to_json(options={})
        to_hash(options).to_json
      end
    end
  end # Xml
end
