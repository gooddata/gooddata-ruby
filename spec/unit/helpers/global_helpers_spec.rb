# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/csv_helper'

describe GoodData::Helpers do
  describe '#diff' do
    before :each do
      @old_tomas = { id: 1, name: 'Tomas', age: 28 }
      @new_tomas = { id: 1, name: "Lil'Tomas", age: 28 }
      @patrick = { id: 4, name: 'Patrick', age: 24 }
      @old_korczis = { id: 3, name: 'Korczis', age: 23 }
      @new_korczis = { id: 3, name: "Korczis", age: 22 }
      @petr = { id: 2, name: 'Petr', age: 32 }
      @cvengy = { id: 5, name: 'Petr', age: 30 }

      @old_list = [@cvengy, @old_tomas, @patrick, @old_korczis]
      @new_list = [@cvengy, @new_tomas, @petr, @new_korczis]
    end

    it 'diffs two lists of hashes' do
      diff = GoodData::Helpers.diff(@old_list, @new_list, key: :id)

      expect(diff[:same]).to eq [@cvengy]
      expect(diff[:added]).to eq [@petr]
      expect(diff[:removed]).to eq [@patrick]
      expect(diff[:changed]).to eq([
        {
          old_obj: @old_tomas,
          new_obj: @new_tomas,
          diff: { name: "Lil'Tomas" }
        },
        {
          old_obj: @old_korczis,
          new_obj: @new_korczis,
          diff: { age: 22 }
        }
      ])
    end

    it 'diffs two lists of hashes on subset of fields' do
      diff = GoodData::Helpers.diff(@old_list, @new_list, key: :id, fields: [:id, :age])

      expect(diff[:same]).to eq [@cvengy, @old_tomas]
      expect(diff[:added]).to eq [@petr]
      expect(diff[:removed]).to eq [@patrick]
      expect(diff[:changed]).to eq([
        {
          old_obj: @old_korczis,
          new_obj: @new_korczis,
          diff: { age: 22 }
        }
      ])
    end

    it 'should encode params and preserve the nil in hidden' do
      x = GoodData::Helpers.decode_params("x" => "y", GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => '{"a":{"b": "c"}}')
      expect(x).to eq("x" => "y", "a" => { "b" => "c" }, "gd_encoded_hidden_params" => nil)
    end

    it 'should encode params and preserve the nil in hidden' do
      x = GoodData::Helpers.decode_params(GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => nil)
      expect(x).to eq("gd_encoded_hidden_params" => nil)
    end

    it 'should encode params and preserve the nil in hidden' do
      x = GoodData::Helpers.decode_params(
        "x" => "y",
        GoodData::Helpers::ENCODED_PARAMS_KEY.to_s => '{"d":{"b": "c"}}',
        GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => '{"a":{"b": "c"}}'
      )
      expect(x).to eq("x" => "y", "a" => { "b" => "c" }, "d" => { "b" => "c" }, "gd_encoded_hidden_params" => nil)
    end

    it 'should encode params and note preserve the nil in public' do
      x = GoodData::Helpers.decode_params("x" => "y", GoodData::Helpers::ENCODED_PARAMS_KEY.to_s => '{"d":{"b": "c"}}')
      expect(x).to eq("x" => "y", "d" => { "b" => "c" })
    end

    it 'should be abe to join datasets' do
      master = [{ id: 'a', x: 1 },
                { id: 'b', x: 1 },
                { id: 'c', x: 2 }]

      lookup = [{ id: 1, y: 'FOO' },
                { id: 2, y: 'BAR' }]

      results = GoodData::Helpers.join(master, lookup, [:x], [:id])
      expect(results).to eq [{ :id => "a", :y => "FOO", :x => 1 },
                             { :id => "b", :y => "FOO", :x => 1 },
                             { :id => "c", :y => "BAR", :x => 2 }]
    end

    it 'should encode secure params' do
      params = {
        "x" => "y",
        "d|b|foo" => "bar",
        "d|b|e|w" => "z",
        GoodData::Helpers::ENCODED_PARAMS_KEY.to_s => '{"d":{"b":{"c": "a"}}}',
        GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => '{"d":{"b":{"e":{"f": "g"}}}}'
      }
      x = GoodData::Helpers.decode_params(params, convert_pipe_delimited_params: true)
      expect(x).to eq(
        "x" => "y",
        "d" => { "b" => { "c" => "a", "e" => { "f" => "g", "w" => "z" }, "foo" => "bar" } },
        "gd_encoded_hidden_params" => nil
      )
    end

    context 'when hidden parameters contain an invalid json' do
      let(:invalid_json) { '{"password": "precious_secret"' }
      let(:params) do
        { GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => invalid_json }
      end

      it 'hides secrets in the error message' do
        expect { GoodData::Helpers.decode_params(params) }.to raise_error(JSON::ParserError) do |e|
          expect(e.message).not_to include('precious_secret')
        end
      end
    end

    it 'should encode reference parameters in gd_encoded_params' do
      params = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "login_password": "abc_${my_password}_123"}'
      }
      expected_result = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'login_password' => 'abc_login_123_123'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'should encode escape reference parameters in gd_encoded_params' do
      params = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "data01": "\\${abc}"}'
      }
      expected_result = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'data01' => '${abc}'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'should encode reference parameters in nested block in gd_encoded_params' do
      params = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'gd_encoded_params' => '{"login_username": "login_user", "ads_client": {"username": "ads_user", "password": "${ads_password}"}}'
      }
      expected_result = {
        'x' => 'y',
        'ads_password' => 'ads_123',
        'my_password' => 'login_123',
        'login_username' => 'login_user',
        'ads_client' => {
          'username' => 'ads_user',
          'password' => 'ads_123'
        }
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end

    it 'should convert all values into String' do
      params = {
        x: true,
        y: ['hello', false],
        z: {
          z1: false,
          z2: [true],
          z3: [[[false]]]
        }
      }
      expected_result = {
        x: 'true',
        y: %w(hello false),
        z: {
          z1: 'false',
          z2: ['true'],
          z3: [[['false']]]
        }
      }
      result = GoodData::Helpers.stringify_values(params)
      expect(result).to eq(expected_result)
    end
  end

  describe '.interpolate_error_message' do
    let(:error_message) { { 'error' => { 'message' => 'foo %s', 'parameters' => ['bar'] } } }

    before do
      @message = GoodData::Helpers.interpolate_error_message(error_message)
    end

    it 'interpolates parameters' do
      expect(@message).to eq('foo bar')
    end

    context 'when error parameter is empty' do
      let(:error_message) { {} }
      it 'returns nil' do
        expect(@message).to be_nil
      end
    end

    context 'when error key is empty' do
      let(:error_message) { { 'error' => {} } }
      it 'returns nil' do
        expect(@message).to be_nil
      end
    end
  end

  describe '.decode_params' do
    it 'interpolates reference parameters in additional_hidden_params' do
      params = {
        'gd_encoded_hidden_params' => '{ "additional_hidden_params": { "secret": "${my_password}" } }',
        'my_password' => "123"
      }
      expected_result = {
        'gd_encoded_hidden_params' => nil,
        'additional_hidden_params' => { 'secret' => '123' },
        'my_password' => '123'
      }
      result = GoodData::Helpers.decode_params(params, :resolve_reference_params => true)
      expect(result).to eq(expected_result)
    end
  end
end
