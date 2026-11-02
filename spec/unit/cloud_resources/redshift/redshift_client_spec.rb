# encoding: UTF-8
#
# Copyright (c) 2010-2026 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

if RUBY_PLATFORM =~ /java/
  require 'gooddata/cloud_resources/redshift/redshift_client'

  describe GoodData::CloudResources::RedshiftClient do
    let(:driver) { double('driver') }
    let(:driver_class) { double('driver_class', new: driver) }
    let(:options) do
      {
        'redshift_client' => {
          'connection' => {
            'url' => 'jdbc:redshift://redshift.example.com:5439',
            'database' => 'db',
            'authentication' => authentication
          }
        }
      }
    end

    # Driver jars are not on the classpath in unit tests, so stub the Java package chain
    before do
      allow(Java).to receive_message_chain('com.amazon.redshift.jdbc42.Driver').and_return(driver_class)
    end

    subject do
      client = described_class.new(options)
      allow(client).to receive_message_chain('com.amazon.redshift.jdbc42.Driver').and_return(driver_class)
      client
    end

    def connect_properties
      received = nil
      allow(driver).to receive(:connect) { |_url, props| received = props }
      subject.connect
      received
    end

    context 'with basic authentication' do
      let(:authentication) { { 'basic' => { 'userName' => 'basic_user', 'password' => 'secret' } } }

      it 'sets user and password to the configured values' do
        props = connect_properties
        expect(props.getProperty('user')).to eq 'basic_user'
        expect(props.getProperty('UID')).to eq 'basic_user'
        expect(props.getProperty('password')).to eq 'secret'
        expect(props.getProperty('PWD')).to eq 'secret'
      end
    end

    context 'with IAM authentication' do
      let(:authentication) do
        { 'iam' => { 'accessKeyId' => 'key_id', 'secretAccessKey' => 'secret_key', 'dbUser' => 'iam_user' } }
      end

      it 'sets user to the configured dbUser' do
        props = connect_properties
        expect(props.getProperty('user')).to eq 'iam_user'
        expect(props.getProperty('UID')).to eq 'iam_user'
        expect(props.getProperty('DbUser')).to eq 'iam_user'
        expect(props.getProperty('AccessKeyID')).to eq 'key_id'
        expect(props.getProperty('SecretAccessKey')).to eq 'secret_key'
      end
    end
  end
end
