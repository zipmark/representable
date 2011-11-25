require 'json'
require 'representable/bindings/json_bindings'

module Representable
  module JSON
    BINDING_FOR_TYPE = {  # TODO: refactor #representable_accessor for better extendability.
      :text     => TextBinding,
    }
    
    def self.included(base)
      base.class_eval do
        include Representable
        extend ClassMethods
      end
    end
    
    
    module ClassMethods
      def binding_for_definition(definition)
        (BINDING_FOR_TYPE[definition.sought_type] or ObjectBinding).new(definition)
      end
    
      # Creates a new Ruby object from XML using mapping information declared in the class.
      #
      # Example:
      #  book = Book.from_xml("<book><name>Beyond Java</name></book>")
      # DISCUSS: assumes shitty wrapping like :article => {:name => ...}
      def from_json(data, *args, &block)
        create_from_json.tap do |object|
          object.from_json(data, *args, &block)
        end
      end
      
      def from_hash(data)
        create_from_json.tap do |object|
          object.update_properties_from(data)
        end
      end
      
    private
      def create_from_json(*args)
        new(*args)
      end
    end
    
    def from_json(data, options={}, &block)
      data = ::JSON[data]
      data = data[self.class.representation_name.to_s] unless options[:wrap] == false
      data ||= {} # FIXME: should we fail here? generate a warning?
      
      update_properties_from(data, &block)
    end
    
    def to_hash(options={})
      hash = create_representation_with({})
      
      # DISCUSS: where to wrap?
      options[:wrap] == false ? hash : {self.class.representation_name => hash}
    end
    
    # Returns a JSON string representing this object.
    def to_json(options={})
      to_hash(options).to_json
    end
  end
end
