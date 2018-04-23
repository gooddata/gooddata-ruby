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
      test_param_four: 4,
      UPPER_case_param: 'qux'
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end
  let(:spec) do
    GoodData::LCM2::BaseAction.define_params(self) do
      description 'Testing param one'
      param :test_param_one, instance_of(GoodData::LCM2::Type::StringType), required: true

      description 'Param four'
      param :test_param_four, instance_of(GoodData::LCM2::Type::StringType), required: false
    end
  end
  it 'verifies required' do
    expect { GoodData::LCM2::Helpers.check_params(spec, params) }.to raise_error(/Mandatory/)
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
    params['test_param_one'] = 'test_param_one'
    expect { GoodData::LCM2::Helpers.check_params(spec, params) }.to raise_error(/has invalid type/)
  end

  it 'fails when unspecified variable is acessed' do
    params.setup_filters(spec)
    expect { params[:test_param_three] }.to raise_error(/not defined in the specification/)
  end

  context 'when created from stringified hash' do
    subject { GoodData::LCM2::Helpers.check_params(spec, params) }
    let(:params) do
      raw_params = { 'update_preference' => { 'keep_data' => false,
                                              'allow_cascade_drops' => true } }
      GoodData::LCM2.convert_to_smart_hash(raw_params)
    end

    let(:spec) do
      GoodData::LCM2::BaseAction.define_params(self) do
        description 'Some param'
        param :update_preference, instance_of(GoodData::LCM2::Type::UpdatePreferenceType), required: false

        description 'Replacement param'
        param :replacement_param, instance_of(GoodData::LCM2::Type::GdClientType), required: false

        description 'Deprecated param'
        param :deprecated_param, instance_of(GoodData::LCM2::Type::StringType), required: false, deprecated: true, replacement: :replacement_param

        description 'List of production tag Names'
        param :production_tags, array_of(instance_of(GoodData::LCM2::Type::StringType)), required: false

        description 'Production Tag Names'
        param :production_tag, instance_of(GoodData::LCM2::Type::StringType), required: false, deprecated: true, replacement: :production_tags

        description 'Default testing param'
        param :default_test, array_of(instance_of(GoodData::LCM2::Type::StringType)), required: false, default: 'default value'

        description 'Deprecated testing param'
        param :deprecated_test, instance_of(GoodData::LCM2::Type::StringType), required: false, deprecated: true, replacement: :default_test
      end
    end

    it 'works with default values' do
      subject
      expect(params[:update_preference][:keep_data]).to be(false)
    end

    context 'when deprecated params together with default values are supplied' do
      let(:params) do
        raw_params = {
          'deprecated_param' => 'franta',
          'production_tag' => 'pepa',
          'update_preference' => {
            'cascade_drops' => true,
            'keep_data' => false
          },
          'deprecated_test' => 'jednicka'
        }
        GoodData::LCM2.convert_to_smart_hash(raw_params)
      end
      it 'works with default values on deprecated params' do
        subject
        expect(params[:update_preference][:keep_data]).to be(false)
        expect(params[:update_preference][:cascade_drops]).to be(true)
      end

      it 'does not fill default values on replacement params if deprecated one has value' do
        subject
        expect(params[:default_test]).to be(nil)
        expect(params[:deprecated_test]).to eq('jednicka')
      end
    end
  end

  context 'when key contains upper-case letters' do
    let(:spec) do
      GoodData::LCM2::BaseAction.define_params(self) do
        description 'Testing param'
        param :upper_case_param, instance_of(GoodData::LCM2::Type::StringType)
      end
    end

    before { params.setup_filters(spec) }

    it 'fetching works with both lower case and original case' do
      ['upper_case_param', :upper_case_param, 'UPPER_case_param', :UPPER_case_param].map { |e| expect(params[e]).to eq('qux') }
    end
  end
end
