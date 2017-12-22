# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

shared_examples 'a blueprint provider' do
  it 'requests model view with includeCA=true' do
    expect(client).to receive(:get).with(
      '/gdc/projects/foo/model/view',
      hash_including(params: hash_including(includeCA: true))
    )
    subject.blueprint(include_ca: true)
  end
end

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

  describe '.transfer_output_stage' do
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

  describe '#blueprint' do
    let(:project_data) do
      {
        'project' => {
          'links' => { 'self' => '/gdc/foo' },
          'meta' => { 'title' => 'My Project' }
        }
      }
    end
    let(:diff_result) do
      { 'asyncTask' => { 'link' => { 'poll' => 'poll_me' } } }
    end
    let(:blueprint) { double(GoodData::Model::ProjectBlueprint) }
    subject { GoodData::Project.new(project_data) }
    before do
      allow(client).to receive(:get).and_return(diff_result)
      allow(client).to receive(:poll_on_code)
      allow(GoodData::Model::FromWire).to receive(:from_wire) .and_return(blueprint)
      allow(blueprint).to receive(:title=)
      subject.client = client
    end

    context 'when include_ca option is true' do
      it_behaves_like 'a blueprint provider'
    end

    context 'when include_ca option is not specified' do
      it_behaves_like 'a blueprint provider'
    end

    context 'when include_ca option is false' do
      it 'requests model view with includeCA=false' do
        expect(client).to receive(:get).with(
          '/gdc/projects/foo/model/view',
          hash_including(params: hash_including(includeCA: false))
        )
        subject.blueprint(include_ca: false)
      end
    end
  end
end
