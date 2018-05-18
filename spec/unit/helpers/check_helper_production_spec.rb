require 'gooddata/lcm/actions/base_action'
require 'gooddata/lcm/helpers/check_helper'
require 'gooddata/lcm/types/types'

describe 'GoodData::LCM2::Helpers::Check' do
  let(:params) do
    params = { test_param_three: 'Testing param three' }
    GoodData::LCM2.convert_to_smart_hash(params)
  end
  let(:spec) do
    GoodData::LCM2::BaseAction.define_params(self) do
      description 'Testing param two'
      param :test_param_two, instance_of(GoodData::LCM2::Type::StringType), required: true

      description 'Testing param four'
      param :test_param_three, instance_of(GoodData::LCM2::Type::IntegerType), required: false
    end
  end
  context 'when running outside the tests' do
    let(:mocked_logger) { double(Logger) }
    before do
      expect(GoodData).to receive(:logger).and_return(mocked_logger)
      expect(ENV).to receive(:[]).with('RSPEC_ENV').and_return('production')
      expect(mocked_logger).to receive(:error)
    end
    it 'writes out error message but do not fail when virifying required params' do
      expect { GoodData::LCM2::Helpers.check_params(spec, params) }.not_to raise_error(/Mandatory/)
    end

    it 'writes out error message but do not fail when checking types' do
      expect { GoodData::LCM2::Helpers.check_params(spec, params) }.not_to raise_error(/has invalid type/)
    end
  end
end
