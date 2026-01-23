# frozen_string_literal: true

require_relative '../queries/type_query'

module LowType
  module Syntax
    refine Array.singleton_class do
      def [](*expression)
        if Low::TypeQuery.type?(expression.first) || Low::TypeQuery.typed_array?(expression:)
          return Low::TypeExpression.new(type: [*expression])
        end

        super
      end
    end

    refine Hash.singleton_class do
      def [](type)
        return Low::TypeExpression.new(type:) if Low::TypeQuery.type?(type)

        super
      end
    end
  end
end
