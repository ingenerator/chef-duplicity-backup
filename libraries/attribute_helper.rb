module Ingenerator
  module DuplicityBackup

    ##
    # Thrown if one or more config variables for a given backup aren't present
    # or have empty values.
    # - eg the backup destination for a given backup is not set
    #
    class IncompleteConfigError < RuntimeError
      def initialize(attr_path)
        super "You must specify a value for node.#{attr_path}"
      end
    end

    ##
    # Get the value of an attribute from .-separated path, throw if missing
    #
    # @param [String] dot-separated path to node attribute required
    # @return [String]
    #
    def self.require_attribute!(node, attribute_path)
      keys = attribute_path.split('.')
      value = keys.inject(node.attributes) do |attributes, key|
        attributes[key] if attributes && attributes.key?(key)
      end

      raise IncompleteConfigError, attribute_path unless value
      value
    end

  end
end
