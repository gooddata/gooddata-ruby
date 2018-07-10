# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::CollectSegments do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:logger) { double(Logger) }
  let(:data_product) { double(GoodData::DataProduct) }
  let(:segment) { double(GoodData::Segment) }
  let(:segment_master) { double(GoodData::Project) }
  let(:params) do
    {
      gdc_gd_client: gdc_gd_client,
      gdc_logger: logger,
      data_product: data_product
    }
  end

  let(:converted_params) { GoodData::LCM2.convert_to_smart_hash(params) }

  subject do
    GoodData::LCM2.run_action(
      GoodData::LCM2::CollectSegments,
      converted_params
    )
  end

  before do
    allow(gdc_gd_client).to receive(:class) { GoodData::Rest::Client }
    allow(logger).to receive(:class) { Logger }
    allow(logger).to receive(:info)
    allow(data_product).to receive(:class) { GoodData::DataProduct }
    allow(data_product).to receive(:segments) { [segment] }
    allow(segment).to receive(:master_project) { segment_master }
    allow(segment).to receive(:segment_id) { 'premium' }
    allow(segment).to receive(:uri) { '/segments/premium' }
    allow(segment_master).to receive(:pid) { '123456' }
    allow(segment_master).to receive(:driver) { 'vertica' }
    allow(segment_master).to receive(:title) { 'Master #1' }
  end

  it 'sets segment_master parameter' do
    subject[:params][:segments].each do |segment|
      expect(segment[:segment_master]).to be(segment_master)
    end
  end
end
