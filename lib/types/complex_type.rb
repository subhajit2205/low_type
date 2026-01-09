# frozen_string_literal: true

module LowType
  module ComplexType
    def match?(value:)
      return true if value.instance_of?(self.class) || value.instance_of?(superclass)

      false
    end
  end
end
