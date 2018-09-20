# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::Domain do
  let(:rest_client) { double(GoodData::Rest::Client) }
  describe '.add_user' do
    subject { GoodData::Domain.add_user(user_data, 'foo', options) }
    before do
      allow(rest_client).to receive(:post) { {} }
      allow(rest_client).to receive(:get) do
        { 'accountSetting' => {} }
      end
      allow(rest_client).to receive(:create)
    end

    context 'when no password specified' do
      let(:user_data) { {} }
      let(:options) { { client: rest_client } }
      let(:password) { 'extrasafe!' }
      it 'generates one' do
        expect(GoodData::Helpers::CryptoHelper).to receive(:generate_password)
          .and_return(password)
        expect(rest_client).to receive(:post).with(
          '/gdc/account/domains/foo/users',
          accountSetting: hash_including(password: password)
        )
        subject
      end
    end
  end
end
