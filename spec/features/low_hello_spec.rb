# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/low_hello'

RSpec.describe LowHello do
  subject(:hello) { described_class.new(greeting, name) }

  let(:greeting) { 'Hey' }
  let(:name) { 'Mate' }

  describe '.included' do
    it 'redefines methods on class load' do
      expect(described_class.low_methods.keys).to include(
        :initialize,
        :typed_arg,
        :typed_arg_without_body,
        :typed_arg_and_default_value,
        :typed_arg_and_invalid_default_value,
        :typed_arg_and_typed_default_value,
        :typed_arg_and_invalid_default_typed_value,
        :multiple_typed_args,
        :multiple_typed_args_and_default_value,
        :typed_array_arg,
        :private_typed_arg
      )
    end
  end

  describe '#initialize' do
    it 'instantiates a typed class' do
      expect { hello }.not_to raise_error
    end

    context 'when the arg type is incorrect' do
      let(:greeting) { 123 }
      let(:error_message) { "Invalid argument type 'Integer' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an invalid type error' do
        expect { hello }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg' do
    it 'passes through the argument' do
      expect(hello.typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { hello.typed_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_without_body' do
    it 'returns nil' do
      expect(hello.typed_arg_without_body('Hola')).to eq(nil)
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { hello.typed_arg_without_body }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(hello.typed_arg_and_default_value('Howdy')).to eq('Howdy')
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(hello.typed_arg_and_default_value).to eq('Hello')
      end
    end
  end

  describe '#typed_arg_and_invalid_default_value' do
    it 'passes through the argument' do
      expect(hello.typed_arg_and_invalid_default_value('Howdy')).to eq('Howdy')
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'Integer' for parameter 'greeting'. Valid types: 'String'" }

      it 'raises an argument type error' do
        # => raises Low::ArgumentTypeError. A default value that is not nil still has to be an allowed type.
        expect { hello.typed_arg_and_invalid_default_value }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  # Types as values.

  describe '#typed_arg_and_typed_default_value' do
    it 'passes through the value(Type) argument' do
      expect(hello.typed_arg_and_typed_default_value('Wassup')).to eq('Wassup')
    end

    context 'when no arg provided' do
      it 'provides the default value (which is a type)' do
        expect(hello.typed_arg_and_typed_default_value).to eq(String)
      end
    end
  end

  describe '#typed_arg_and_invalid_default_typed_value' do
    it 'passes through the argument' do
      expect(hello.typed_arg_and_invalid_default_typed_value('Wassup')).to eq('Wassup')
    end

    context 'when no arg provided' do
      let(:error_message) do
        "Invalid argument type 'Integer' for parameter 'greeting'. Valid types: 'String | [Symbol]'"
      end

      it 'raises an argument type error' do
        # => raises Low::ArgumentTypeError. A default value(type) that is not nil still has to be an allowed type.
        expect do
          hello.typed_arg_and_invalid_default_typed_value
        end.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  # Multiple types.

  describe '#multiple_typed_args' do
    it 'passes through both arguments types' do
      expect(hello.multiple_typed_args('Shalom')).to eq('Shalom')
      expect(hello.multiple_typed_args(123)).to eq(123)
    end

    context 'when arg is wrong type' do
      let(:error_message) do
        "Invalid argument type 'TrueClass' for parameter 'greeting'. Valid types: 'String | Integer'"
      end

      it 'raises an invalid type error' do
        expect { hello.multiple_typed_args(true) }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when no arg is provided' do
      let(:error_message) do
        "Invalid argument type 'NilClass' for parameter 'greeting'. Valid types: 'String | Integer'"
      end

      it 'raises an argument error' do
        expect { hello.multiple_typed_args }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '#multiple_typed_args_and_default_value' do
    it 'passes through both arguments types' do
      expect(hello.multiple_typed_args_and_default_value('Shalom')).to eq('Shalom')
      expect(hello.multiple_typed_args_and_default_value(123)).to eq(123)
    end

    context 'when arg is wrong type' do
      let(:error_message) do
        "Invalid argument type 'TrueClass' for parameter 'greeting'. Valid types: 'String | Integer'"
      end

      it 'raises an argument type error' do
        expect do
          hello.multiple_typed_args_and_default_value(true)
        end.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when no arg is provided' do
      it 'provides the default value' do
        expect(hello.multiple_typed_args_and_default_value).to eq('Salutations')
      end
    end
  end

  # Enumerables.

  describe '#typed_array_arg' do
    it 'passes through the argument' do
      expect(hello.typed_array_arg(%w[Hi Hey Howdy])).to eq(%w[Hi Hey Howdy])
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'greetings'. Valid types: '[String]'" }

      it 'raises an argument error' do
        expect { hello.typed_array_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when nil is not the first element' do
      let(:error_message) { "Invalid argument type 'Array' for parameter 'greetings'. Valid types: '[String]'" }
      let(:greetings) { ['Hi', nil, 'Howdy'] }

      context 'without deep type check' do
        it 'passes through the argument' do
          expect(hello.typed_array_arg(greetings)).to eq(greetings)
        end
      end

      context 'with deep type check' do
        before { LowType.configure { |config| config.deep_type_check = true } }
        after { LowType.configure { |config| config.deep_type_check = false } }

        it 'raises an argument error' do
          expect { hello.typed_array_arg(greetings) }.to raise_error(Low::ArgumentTypeError, error_message)
        end
      end
    end
  end

  describe '#typed_nilable_array_arg' do
    it 'passes through the argument' do
      expect(hello.typed_nilable_array_arg([nil, 'Farwell', 'See ya'])).to eq([nil, 'Farwell', 'See ya'])
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'goodbyes'. Valid types: '[String | nil]'" }

      it 'raises an argument error' do
        expect { hello.typed_nilable_array_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end

    context 'when nil is not the first element' do
      let(:error_message) { "Invalid argument type 'Array' for parameter 'goodbyes'. Valid types: '[String]'" }
      let(:goodbyes) { ['Farewell', nil, 'See ya'] }

      context 'without deep type check' do
        it 'passes through the argument' do
          expect(hello.typed_nilable_array_arg(goodbyes)).to eq(goodbyes)
        end
      end

      context 'with deep type check' do
        before { LowType.configure { |config| config.deep_type_check = true } }
        after { LowType.configure { |config| config.deep_type_check = false } }

        it 'passes through the argument' do
          expect(hello.typed_nilable_array_arg(goodbyes)).to eq(goodbyes)
        end
      end
    end
  end

  describe '#typed_nilable_array_arg_and_default_nil' do
    let(:greetings) { ['Hi', nil, 'Howdy'] }

    it 'passes through the argument' do
      expect(hello.typed_nilable_array_arg_and_default_nil(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default nil' do
        expect(hello.typed_nilable_array_arg_and_default_nil).to eq(nil)
      end
    end
  end

  describe '#typed_array_arg_and_default_nil' do
    let(:greetings) { %w[Hi Hey Howdy] }

    it 'passes through the argument' do
      expect(hello.typed_array_arg_and_default_nil(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default nil' do
        expect(hello.typed_array_arg_and_default_nil).to eq(nil)
      end
    end
  end

  describe '#typed_array_arg_and_default_value' do
    let(:greetings) { %w[Hi Hey Howdy] }

    it 'passes through the argument' do
      expect(hello.typed_array_arg_and_default_value(greetings)).to eq(greetings)
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(hello.typed_array_arg_and_default_value).to eq(greetings)
      end
    end
  end

  describe '#private_typed_arg' do
    let(:error_message) { "private method 'private_typed_arg' called for an instance of LowHello" }

    it 'raises no method error' do
      expect { hello.private_typed_arg }.to raise_error(NoMethodError, error_message)
    end
  end
end
