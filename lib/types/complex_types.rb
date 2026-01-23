# frozen_string_literal: true

require_relative '../factories/type_factory'
require_relative 'status'

module Low
  COMPLEX_TYPES = [
    Boolean = TypeFactory.complex_type(Object),
    Headers = TypeFactory.complex_type(Hash),
    HTML = TypeFactory.complex_type(String),
    JSON = TypeFactory.complex_type(String),
    Status,
    Tuple = TypeFactory.complex_type(Array),
    XML = TypeFactory.complex_type(String)
  ].freeze
end
