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
        alias_method :from_json, :update_properties_from
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
      def from_json(data, options={})
        # DISCUSS: extract #from_json call in Bindings to this place.
        data = ::JSON[data] if data.is_a?(String) # DISCUSS: #from_json sometimes receives a string (in nestings).
        data ||= {} # DISCUSS: is this needed?
        data = data[representation_name.to_s] unless options[:wrap] == false
        data ||= {} # FIXME: should we fail here? generate a warning?
        
        create_from_json.tap do |object|
          object.update_properties_from(data)
        end
      end
      
    private
      def create_from_json(*args)
        new(*args)
      end
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
