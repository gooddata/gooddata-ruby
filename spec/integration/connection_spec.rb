# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../helpers/connection_helper'

describe GoodData, :vcr, :vcr_all_cassette => 'sso' do
  let(:login) { 'rubydev+admin@gooddata.com' }
  KEYS = ['dev-gooddata-sso.pub', 'rubydev_public.gpg', 'rubydev_secret_keys.gpg']

  before do
    cipher = ENV['GD_SPEC_PASSWORD'] || ENV['BIA_ENCRYPTION_KEY']
    KEYS.each do |key|
      File.write(key, GoodData::Helpers.decrypt(File.read(key + '.encrypted'), cipher))
    end

    `gpg --import #{KEYS.join(' ')}`

    live_api = GoodData::Environment::VCR_ON == false || VCR.current_cassette.recording?
    allow(GoodData).to receive(:system) { true } unless live_api
  end

  it 'can use SSO' do
    rest_client = GoodData.connect_sso(
      login,
      'test-ruby',
      GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
      server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
      verify_ssl: false
    )
    user = rest_client.domain(GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN).users(login, client: rest_client)
    expect(user).to be_truthy
  end

  after do
    KEYS.each { |key| File.delete(key) }
  end
end
