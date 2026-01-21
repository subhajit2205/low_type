# frozen_string_literal: true

###
# Type expressions from union types.
#
# The "|" pipe syntax requires a monkey-patch but can be disabled if you don't need union types with default values.
# This is the only monkey-patch in the entire library and is a relatively harmless one.
# @see LowType.config.union_type_expressions
###
class Object
  # For "Type | [type_expression/type/value]" situations, convert type into a type expression to continue the chain.
  # "|" is not defined on Object class and this is the most compute-efficient way to achieve our goal (world peace).
  # "|" is overridable by any child object. While we could def/undef this method, this approach is actually lighter.
  # "|" bitwise operator on Integer is not defined when the receiver is an Integer class, so we are not in conflict.
  class << self
    def |(expression)
      ::LowType::TypeExpression.new(type: self) | expression
    end
  end
end
