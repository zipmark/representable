require 'nokogiri'

Nokogiri::XML::Node.class_eval do
  def add_node(name)
    add_child Nokogiri::XML::Node.new(name, document)
  end
  
  # FIXME: remove switch. where is #from used with nodes?
  def self.from(data)
    case data
    when Nokogiri::XML::Node
      data
    when Nokogiri::XML::Document
      data.root
    else
      Nokogiri::XML(data).root
    end
  end
end
