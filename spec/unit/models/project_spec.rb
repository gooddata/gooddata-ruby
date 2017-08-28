# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::Project do
  subject { GoodData::Project }
  let(:from_project) { double('from_project') }
  let(:to_project) { double('to_project') }
  let(:process) { double('process') }
  let(:add) { double('add') }
  let(:output_stage) { double('output_stage') }
  let(:client) { double('client') }
  let(:connection) { double('connection') }
  let(:server) { double('server') }

  before do
    allow(from_project).to receive(:processes).and_return([process])
    allow(to_project).to receive(:processes).and_return([])
    allow(process).to receive(:type).and_return(:dataload)
    allow(to_project).to receive(:add).and_return(add)
    allow(to_project).to receive(:client).and_return(client)
    allow(client).to receive(:connection).and_return(connection)
    allow(connection).to receive(:server).and_return(server)
    allow(from_project).to receive(:add).and_return(add)
    allow(from_project).to receive(:client).and_return(client)
    allow(add).to receive(:output_stage).and_return(output_stage)
  end

  describe '#transfer_output_stage' do
    context 'when source and target domains are different' do
      before do
        allow(server).to receive(:url).and_return('foo', 'bar')
      end

      it 'raises an error' do
        expect { subject.transfer_output_stage(from_project, to_project, {}) }
          .to raise_error(/Cannot transfer output stage from foo to bar/)
      end
    end
  end
end
