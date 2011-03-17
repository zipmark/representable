class Module
  def bool_attr_reader(*attrs)
    attrs.each do |attr|
      define_method :"#{attr}?" do
        instance_variable_get(:"@#{attr}") || false
      end
    end
  end
end

module ROXML
  class ContradictoryNamespaces < StandardError
  end
  class Definition # :nodoc:
    attr_reader :name, :sought_type, :wrapper, :accessor, :namespace
    bool_attr_reader :name_explicit, :array, :cdata

    def initialize(sym, opts = {}, &block)
      @namespace  = opts.delete(:namespace)
      @accessor   = sym.to_s
      
      if opts[:as].is_a?(Array) # DISCUSS: move to ArrayDefinition.
        @array      = true
        @name       = (opts[:tag] || @accessor).to_s
      else
        @name = accessor.to_s.chomp('?')
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
      elsif opts[:from].to_s.starts_with?('@')
        @sought_type = :attr
        opts[:from].sub!('@', '')
      end

      
      #raise ContradictoryNamespaces if @name.include?(':') && (@namespace.present? || @namespace == false)

    end

    def instance_variable_name
      :"@#{accessor}"
    end

    def setter
      :"#{accessor}="
    end

    def name?
      @name == '*'
    end

    def content?
      @name == '.'
    end

    def default
      if @default.nil?
        @default = [] if array?
        @default = {} if hash?
      end
      @default.duplicable? ? @default.dup : @default
    end

    def to_ref(inst)
      case sought_type
      when :attr          then XMLAttributeRef
      when :text          then XMLTextRef
      when :namespace     then XMLNameSpaceRef
      when Symbol         then raise ArgumentError, "Invalid type argument #{sought_type}"
      else                     XMLObjectRef
      end.new(self, inst)
    end

  private
    def self.all(items, &block)
      array = items.is_a?(Array)
      results = (array ? items : [items]).map do |item|
        yield item
      end

      array ? results : results.first
    end

    def extract_type(as)
      return as.first if as.is_a?(Array) and as.size > 0  # TODO: move to ArrayDefinition.
      
      :text
    end
  end
end
