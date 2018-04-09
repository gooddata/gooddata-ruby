# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require 'gooddata/lcm/actions/base_action'
require 'gooddata/lcm/helpers/check_helper'
require 'gooddata/lcm/types/types'

describe 'GoodData::LCM2::Helpers::Check' do
  let(:params) do
    params = {
      test_param_two: 'Testing param two',
      test_param_three: 'Testing param three',
      test_param_four: 4
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end
  it 'verifies required' do
    PARAMS = GoodData::LCM2::BaseAction.define_params(self) do
      description 'Testing param one'
      param :test_param_one, instance_of(GoodData::LCM2::Type::StringType), required: true
    end
    expect { GoodData::LCM2::Helpers.check_params(PARAMS, params) }.to raise_error(/Mandatory/)
  end

  it 'fills default' do
    PARAMS_2 = GoodData::LCM2::BaseAction.define_params(self) do
      description 'Testing param one'
      param :test_param_one, instance_of(GoodData::LCM2::Type::StringType), required: true, default: 'filled_default_value'

      description 'Testing param two'
      param :test_param_two, instance_of(GoodData::LCM2::Type::StringType), required: false
    end
    GoodData::LCM2::Helpers.check_params(PARAMS_2, params)
    expect(params[:test_param_one]).to match(/filled_default_value/)
  end

  it 'checks types' do
    PARAMS_3 = GoodData::LCM2::BaseAction.define_params(self) do
      description 'Testing param four'
      param :test_param_four, instance_of(GoodData::LCM2::Type::StringType), required: false
    end
    expect { GoodData::LCM2::Helpers.check_params(PARAMS_3, params) }.to raise_error(/has invalid type/)
  end

  it 'fails when unspecified variable is acessed' do
    params.setup_filters(PARAMS_3)
    expect { params[:test_param_three] }.to raise_error(/not defined in the specification/)
  end

  context 'when created from stringified hash' do
    let(:raw_params) do
      { 'update_preference' => { 'keep_data' => false,
                                 'allow_cascade_drops' => true } }
    end

    let(:params) do
      GoodData::LCM2.convert_to_smart_hash(raw_params)
    end

    let(:spec) do
      GoodData::LCM2::BaseAction.define_params(self) do
        description 'Test'
        param :update_preference, instance_of(GoodData::LCM2::Type::UpdatePreferenceType), required: false
      end
    end

    it 'it works with default values' do
      GoodData::LCM2::Helpers.check_params(spec, params)
      expect(params[:update_preference][:keep_data]).to be(false)
    end
  end
end
