# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/ensure_technical_users_project'
require 'gooddata/lcm/lcm2'

shared_examples 'a technical users domain action' do
  it 'adds technical user to the domain' do
    expect(domain).to receive(:add_user)
      .with(login: 'foo@bar.com', email: 'foo@bar.com')
    subject.class.call(params)
  end
end

describe GoodData::LCM2::EnsureTechnicalUsersDomain do
  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:domain) { double(:domain) }
  let(:user) { double(:user) }
  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(domain).to receive(:users) { [] }
    allow(user).to receive(:login)
    allow(user).to receive(:email)
    allow(domain).to receive(:add_user) { user }
  end

  context 'when deprecated param technical_user specified' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        domain: domain,
        technical_user: ['foo@bar.com']
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    it_behaves_like 'a technical users domain action'
  end

  context 'when param technical_users specified' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        domain: domain,
        technical_users: ['foo@bar.com']
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    it_behaves_like 'a technical users domain action'
  end
end
