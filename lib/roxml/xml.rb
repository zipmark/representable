require 'nokogiri'
require 'roxml/nokogiri_extensions'

module ROXML  
# FIXME: remove switch. where is #from used with nodes?
  module XML
    class Node
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
  end
end

require 'roxml/xml/references'
