# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
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
          diff: { name: "Lil'Tomas"}
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
      x = GoodData::Helpers.decode_params({ "x" => "y", GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => '{"a":{"b": "c"}}'})
      expect(x).to eq({"x"=>"y", "a"=>{"b"=>"c"}, "gd_encoded_hidden_params"=>nil})
    end

    it 'should encode params and preserve the nil in hidden' do
      x = GoodData::Helpers.decode_params({GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => nil})
      expect(x).to eq({"gd_encoded_hidden_params" =>nil})
    end

    it 'should encode params and preserve the nil in hidden' do
      x = GoodData::Helpers.decode_params({
        "x" => "y",
        GoodData::Helpers::ENCODED_PARAMS_KEY.to_s => '{"d":{"b": "c"}}',
        GoodData::Helpers::ENCODED_HIDDEN_PARAMS_KEY.to_s => '{"a":{"b": "c"}}'
      })
      expect(x).to eq({
        "x"=>"y",
        "a"=>{"b"=>"c"},
        "d" => {"b" => "c"},
        "gd_encoded_hidden_params"=>nil
      })
    end

    it 'should encode params and note preserve the nil in public' do
      x = GoodData::Helpers.decode_params({
        "x" => "y",
        GoodData::Helpers::ENCODED_PARAMS_KEY.to_s => '{"d":{"b": "c"}}'
      })
      expect(x).to eq({
        "x"=>"y",
        "d" => {"b" => "c"}
      })
    end

    it 'should be abe to join datasets' do
      master = [{ id: 'a', x: 1 },
                { id: 'b', x: 1 },
                { id: 'c', x: 2 }]

      lookup = [{ id: 1, y: 'FOO' },
                { id: 2, y: 'BAR' }]

      results = GoodData::Helpers.join(master, lookup, [:x], [:id])
      expect(results).to eq [{:id=>"a", :y=>"FOO", :x=>1},
                             {:id=>"b", :y=>"FOO", :x=>1},
                             {:id=>"c", :y=>"BAR", :x=>2}]
    end

  end
end
