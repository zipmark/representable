module ROXML
  require 'nokogiri'
  require 'roxml/xml/parsers/nokogiri'

# FIXME: remove switch.
  module XML
    class Node
      def self.from(data)
        case data
        when XML::Node
          data
        when XML::Document
          data.root
        when File, IO
          XML.parse_io(data).root
        else
          if (defined?(URI) && data.is_a?(URI::Generic)) ||
             (defined?(Pathname) && data.is_a?(Pathname))
            XML.parse_file(data.to_s).root
          else
            XML.parse_string(data).root
          end
        end
      end
    end
  end
end

require 'roxml/xml/references'
