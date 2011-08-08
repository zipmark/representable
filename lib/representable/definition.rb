module Representable
  class Definition # :nodoc:
    attr_reader :name, :sought_type, :wrapper, :accessor, :namespace
    
    
    def initialize(sym, opts={})
      @accessor   = sym.to_s
      @namespace  = opts.delete(:namespace)
      
      
      if opts[:as].is_a?(Array) # DISCUSS: move to ArrayDefinition.
        @array      = true
        @name       = (opts[:tag] || @accessor).to_s
      else
        @name = accessor
        @name = (opts[:from] || @name).to_s
      end

      @sought_type = extract_type(opts[:as])
      if @sought_type.respond_to?(:roxml_tag_name)
        opts[:from] ||= @sought_type.roxml_tag_name
      end

      if opts[:from] == :content
        opts[:from] = '.'
      elsif opts[:from] == :name
        opts[:from] = '*'
      elsif opts[:from] == :attr
        @sought_type = :attr
        opts[:from] = nil
      elsif opts[:from] == :namespace
        opts[:from] = '*'
        @sought_type = :namespace
      elsif opts[:from].to_s =~ /^@/  # FIXME: move me to xml.
        @sought_type = :attr
        opts[:from].sub!('@', '')
      end
    end

    def instance_variable_name
      :"@#{accessor}"
    end

    def setter
      :"#{accessor}="
    end
    
    def typed?
      sought_type.is_a?(Class)
    end
    
    def name?
      @name == '*'
    end

    def content?
      @name == '.'
    end
    
    def array?
      @array
    end
    
    def cdata?  # FIXME: move to XML!
      @cdata
    end
    
    
    # Applies the block to +value+ which might also be a collection.
    def apply(value)
      return value unless value # DISCUSS: is that ok here?
      
      if array?
        value = value.collect do |item|
          yield item
        end
      else
        value = yield value
      end
      
      value
    end

  private
    def extract_type(as)
      as = as.first if as.is_a?(Array)  # TODO: move to ArrayDefinition.
      
      as || :text
    end
  end
end
