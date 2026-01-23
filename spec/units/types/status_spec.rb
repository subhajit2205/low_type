# frozen_string_literal: true

require_relative '../../../lib/types/status'

RSpec.describe Low::Status do
  subject(:status) { Low::Status[200] }

  describe '.[]' do
    it 'creates a status code' do
      expect(status.status_code).to eq(200)
    end

    it 'validates a status code' do
      expect { Low::Status[999] }.to raise_error(Low::AllowedTypeError)
    end
  end

  describe '#==' do
    it 'does value comparison' do
      expect(Low::Status[200]).to eq(Low::Status[200])
    end
  end

  describe '#hash' do
    let(:hash) do
      { Low::Status[200] => 1 }
    end

    it 'does value comparison' do
      hash[Low::Status[200]] = 2

      expect(hash.count).to eq(1)
    end
  end
end
