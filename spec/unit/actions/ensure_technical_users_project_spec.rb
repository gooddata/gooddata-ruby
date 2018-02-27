# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/ensure_technical_users_project'
require 'gooddata/lcm/lcm2'

shared_examples 'a technical users project action' do
  it 'adds technical user to the project' do
    expect(project).to receive(:create_users).with([{ login: 'foo@bar.com', role: 'admin' }])
    result = subject.class.call(params)
    expected = [{ project: 'foo project',
                  pid: 'abcdefg',
                  login: 'foo@bar.com',
                  role: 'admin',
                  result: 'successful',
                  message: 'yahoo!',
                  url: '/gdc/account/foo' }]
    expect(result).to eq(expected)
  end
end

describe GoodData::LCM2::EnsureTechnicalUsersProject do
  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:project) { double(:project) }
  let(:domain) { double(:domain) }
  before do
    allow(project).to receive(:title) { 'foo project' }
    allow(project).to receive(:pid) { 'abcdefg' }
    allow(project).to receive(:create_users) { [{ type: 'successful', message: 'yahoo!', user: '/gdc/account/foo' }] }
    allow(gdc_gd_client).to receive(:projects) { project }
  end

  context 'when user wants to assign an existing project to new client' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        technical_users: ['foo@bar.com'],
        synchronize: [],
        domain: domain,
        clients: [{ project: 'abcdefg' }]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it_behaves_like 'a technical users project action'
  end

  context 'when deprecated param technical_user specified' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        technical_user: ['foo@bar.com'],
        domain: domain,
        synchronize: [{ to: [{ pid: 'qux' }] }]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    it_behaves_like 'a technical users project action'
  end

  context 'when param technical_users specified' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        domain: domain,
        technical_users: ['foo@bar.com'],
        synchronize: [{ to: [{ pid: 'qux' }] }]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    it_behaves_like 'a technical users project action'
  end
end
