require 'puppet/parser/expression/branch'

class Puppet::Parser::Expression
  # An Expression node to call a function.
  class Function < Expression::Branch

    associates_doc

    attr_accessor :name, :arguments

    

    def compute_denotation(scope)

      # Make sure it's a defined function
      raise Puppet::ParseError, "Unknown function #{@name}" unless @fname

      # Now check that it's been used correctly
      case @ftype
      when :rvalue
        raise Puppet::ParseError, "Function '#{@name}' does not return a value" unless Puppet::Parser::Functions.rvalue?(@name)
      when :statement
        if Puppet::Parser::Functions.rvalue?(@name)
          raise Puppet::ParseError,
            "Function '#{@name}' must be the value of a statement"
        end
      else
        raise Puppet::DevError, "Invalid function type #{@ftype.inspect}"
      end



      # We don't need to evaluate the name, because it's plaintext
      args = @arguments.denotation(scope)

      scope.send("function_#{@name}", args)
    end

    def initialize(hash)
      @ftype = hash[:ftype] || :rvalue
      hash.delete(:ftype) if hash.include? :ftype

      super(hash)

      @fname = Puppet::Parser::Functions.function(@name)
      # Lastly, check the parity
    end

    def to_s
      args = arguments.is_a?(ArrayConstructor) ? arguments.to_s.gsub(/\[(.*)\]/,'\1') : arguments
      "#{name}(#{args})"
    end
  end
end
