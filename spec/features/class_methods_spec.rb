# frozen_string_literal: true

require_relative '../../lib/types/error_types'
require_relative '../fixtures/class_methods'

RSpec.describe ClassMethods do
  describe '.included' do
    it 'redefines methods on class load' do
      expect(described_class.low_methods.keys).to include(
        :inline_class_typed_arg,
        :class_typed_arg,
        :class_typed_arg_and_default_value
      )
    end
  end

  describe '.inline_class_typed_arg' do
    it 'passes through the argument' do
      expect(described_class.inline_class_typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'goodbye'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { described_class.inline_class_typed_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '.class_typed_arg' do
    it 'passes through the argument' do
      expect(described_class.class_typed_arg('Hi')).to eq('Hi')
    end

    context 'when no arg provided' do
      let(:error_message) { "Invalid argument type 'NilClass' for parameter 'goodbye'. Valid types: 'String'" }

      it 'raises an argument error' do
        expect { described_class.class_typed_arg }.to raise_error(Low::ArgumentTypeError, error_message)
      end
    end
  end

  describe '.class_typed_arg_and_default_value' do
    it 'passes through the argument' do
      expect(described_class.class_typed_arg_and_default_value('Goodbye')).to eq('Goodbye')
    end

    context 'when no arg provided' do
      it 'provides the default value' do
        expect(described_class.class_typed_arg_and_default_value).to eq('Bye')
      end
    end
  end
end
