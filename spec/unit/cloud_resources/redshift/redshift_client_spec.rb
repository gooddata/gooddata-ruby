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

    describe '#realize_query' do
      let(:authentication) { { 'basic' => { 'userName' => 'basic_user', 'password' => 'secret' } } }
      let(:metadata) { double('metadata', column_count: 3) }
      let(:result) { double('result') }
      let(:statement) { double('statement', execute: true, get_result_set: result) }
      let(:connection) { double('connection', create_statement: statement, close: nil) }

      before do
        allow(driver).to receive(:connect).and_return(connection)
        allow(result).to receive(:get_meta_data).and_return(metadata)
        allow(metadata).to receive(:get_column_name) { |i| %w[name active deleted][i - 1] }
        allow(metadata).to receive(:get_column_type) do |i|
          [java.sql.Types::VARCHAR, java.sql.Types::BIT, java.sql.Types::BOOLEAN][i - 1]
        end
        allow(result).to receive(:next).and_return(true, true, false)
        allow(result).to receive(:get_string).with(1).and_return('Alice', 'Bob')
        # Driver 2.x getString() returns BOOLEAN as "t"/"f"
        allow(result).to receive(:get_string).with(2).and_return('t', 'f')
        allow(result).to receive(:get_boolean).with(2).and_return(true, false)
        allow(result).to receive(:get_boolean).with(3).and_return(false, false)
        allow(result).to receive(:was_null).and_return(false, false, false, true)
      end

      it 'writes BOOLEAN columns as true/false and NULL as empty' do
        Dir.mktmpdir do |dir|
          Dir.chdir(dir) do
            rows = CSV.read(subject.realize_query('SELECT 1', nil))
            expect(rows).to eq [%w[name active deleted], %w[Alice true false], ['Bob', 'false', nil]]
          end
        end
      end
    end
  end
end
