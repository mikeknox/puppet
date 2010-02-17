require 'puppet/parser/expression/branch'

class Puppet::Parser::Expression
  # A statement syntactically similar to an ResourceDef, but uses a
  # capitalized object type and cannot have a name.
  class ResourceDefaults < Expression::Branch
    attr_accessor :type, :parameters

    associates_doc

    # As opposed to ResourceDef, this stores each default for the given
    # object type.
    def compute_denotation(scope)
      # Use a resource reference to canonize the type
      ref = Puppet::Resource.new(@type, "whatever")
      type = ref.type
      params = @parameters.denotation(scope)

      parsewrap do
        scope.setdefaults(type, params)
      end
    end
  end
end
