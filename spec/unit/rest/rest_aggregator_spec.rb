# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/rest/rest'

describe GoodData::Rest::Aggregator do
  let(:stat1) { { :method => "POST", :endpoint => '/gdc/projects/{id}', :duration => 1, :domain => "test.com" } }
  let(:stat2) { { :method => "POST", :endpoint => '/gdc/projects/{id}', :duration => 2, :domain => "test.com" } }

  # Simple wrapper for Aggregator module
  class AggregatorWrapper
    include GoodData::Rest::Aggregator
    def initialize
      initialize_store
    end
  end

  let(:aggregator) { AggregatorWrapper.new }

  it 'Should be empty' do
    expect(aggregator.store).to be_empty
  end

  it 'Should add two stats of the same type' do
    aggregator.update_store(stat1[:domain], stat1[:method], stat1[:duration], stat1[:endpoint])
    aggregator.update_store(stat2[:domain], stat2[:method], stat2[:duration], stat2[:endpoint])
    expect(aggregator.store).to eq(
      "test.com".to_sym => {
        :POST => {
          "/gdc/projects/{id}".to_sym => {
            :min => 1, :max => 2,
            :avg => 1.5, :count => 2,
            :method => "POST",
            :endpoint => "/gdc/projects/{id}",
            :domain => "test.com"
          }
        }
      }
    )
  end
end
