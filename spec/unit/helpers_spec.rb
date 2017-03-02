# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/client'
require 'gooddata/models/model'

describe GoodData::Helpers do
  describe '#home_directory' do
    it 'works' do
      GoodData::Helpers.home_directory
    end
  end

  describe '#running_on_windows?' do
    it 'works' do
      result = GoodData::Helpers.running_on_windows?
      # rubocop:disable Style/DoubleNegation
      !!result.should == result
      # rubocop:enable Style/DoubleNegation
    end
  end

  describe '#running_on_mac?' do
    it 'works' do
      result = GoodData::Helpers.running_on_a_mac?
      # rubocop:disable Style/DoubleNegation
      !!result.should == result
      # rubocop:enable Style/DoubleNegation
    end
  end

  describe '#error' do
    it 'works' do
      expect { GoodData::Helpers.error('Test Error') }.to raise_error(SystemExit)
    end
  end

  describe '#find_goodfile' do
    it 'works' do
      GoodData::Helpers.find_goodfile.should_not be_nil
    end
  end

  describe "#decode_params" do
    it 'decodes the data params from json' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'gd_encoded_params' => '{"deep": {"deeper": "deep value"}}'
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'deep' => {
          'deeper' => 'deep value'
        }
      }
      result = GoodData::Helpers.decode_params(params)
      expect(result).to eq(expected_result)
    end
    it 'decodes the hidden_data in hidden params' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'gd_encoded_hidden_params' => '{"deep_secret": {"deeper_secret": "hidden value"}}'
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        "gd_encoded_hidden_params" => nil,
        "deep_secret" => {
          "deeper_secret" => "hidden value"
        }
      }
      result = GoodData::Helpers.decode_params(params)
      expect(result).to eq(expected_result)
    end

    it 'decodes the reference parameters in gd_encoded_params in String form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "login_password": "${my_password}", "data01": "\\\\${my_password}", "data02":"abc\\\\def"}'
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'login_password' => 'login_123',
        'data01' => '\\login_123',
        'data02' => 'abc\\def'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'decodes the reference parameters in gd_encoded_params in Hash form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => { "login_username" => "login_user", "login_password" => "${my_password}", "data01" => "\\\\${my_password}", "data02" => "abc\\def" }
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'login_password' => 'login_123',
        'data01' => '\\login_123',
        'data02' => 'abc\\def'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'decodes escape the reference parameters in gd_encoded_params in String form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "data01": "\\${abc}"}'
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'data01' => '${abc}'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'decodes escape the reference parameters in gd_encoded_params in Hash form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => { "login_username" => "login_user", "data01" => "\\${abc}" }
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'data01' => '${abc}'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'decodes the reference parameters in nested block in gd_encoded_params in String form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "login_password": "${my_password}", "ads_client": {"username": "ads_user", "password": "${ads_password}"}}'
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'login_password' => 'login_123',
        'ads_client' => {
          'username' => 'ads_user',
          'password' => 'ads_123'
        }
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'decodes the reference parameters in nested block in gd_encoded_params in Hash form' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => { "login_username" => "login_user", "login_password" => "${my_password}", "ads_client" => { "username" => "ads_user", "password" => "${ads_password}" } }
      }
      expected_result = {
        'param' => 'value',
        'number_param' => 5,
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'login_password' => 'login_123',
        'ads_client' => {
          'username' => 'ads_user',
          'password' => 'ads_123'
        }
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'throws an error when data params is not a valid json' do
      params = {
        'param' => 'value',
        'number_param' => 5,
        'gd_encoded_params' => 'This is no json.'
      }
      expect { GoodData::Helpers.decode_params(params) }.to raise_error(JSON::ParserError)
    end
  end
end
