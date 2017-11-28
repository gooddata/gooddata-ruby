# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::CollectUsersBrickUsers do
  let(:data_source) { double('data_source') }
  let(:users_csv) do
  end

  let(:params) do
    params = {
      users_brick_config: {
        input_source: {},
        login_column: 'Email'
      }
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(GoodData::Helpers::DataSource).to receive(:new)
      .and_return(data_source)
    allow(data_source).to receive(:realize)
      .and_return('spec/data/users.csv')
  end

  it 'enriches parameters with logins' do
    result = subject.class.call(params)
    expect(result[:results].length).to eq(11)
    result[:results].each do |user|
      expect(user[:login]).not_to be_nil
    end
  end
end
