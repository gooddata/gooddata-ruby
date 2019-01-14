module GoodData
  # Simplifies creating mocks of commonly used objects
  class MockFactory
    class << self
      include RSpec::Mocks::ExampleMethods

      def schedule_mock(name, process_id)
        mock = double(GoodData::Schedule)
        allow(mock).to receive(:name) { name }
        allow(mock).to receive(:process_id) { process_id }
        mock
      end

      def process_mock(name, id)
        mock = double(GoodData::Process)
        allow(mock).to receive(:name) { name }
        allow(mock).to receive(:process_id) { id }
        mock
      end
    end
  end
end
