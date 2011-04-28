module ROXML
  require 'nokogiri'
  require 'roxml/xml/parsers/nokogiri'

# FIXME: remove switch. where is #from used with nodes?
  module XML
    class Node
      def self.from(data)
        case data
        when XML::Node
          data
        when XML::Document
          data.root
        else
          XML.parse_string(data).root
        end
      end
    end
  end
end

require 'roxml/xml/references'
