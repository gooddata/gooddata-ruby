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
  let(:from_project) { double(GoodData::Project) }
  let(:to_project) { double(GoodData::Project) }
  let(:process) { double(GoodData::Process) }
  let(:add) { double(GoodData::AutomatedDataDistribution) }
  let(:output_stage) { double(GoodData::AdsOutputStage) }
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
    let(:original_prefix) { 'im_the_original_prefix' }
    let(:prefix) { 'its_a_prefix' }
    let(:stage_uri) { 'foo.bar/baz' }

    before do
      allow(server).to receive(:url).and_return('foo', 'foo')
      allow(output_stage).to receive(:schema)
      allow(output_stage).to receive(:client_id) { 'mahnert biscuits ltd' }
      allow(add).to receive(:output_stage=)
      allow(output_stage).to receive(:output_stage_prefix).and_return(original_prefix)
    end

    context 'when source and target domains are different' do
      before do
        allow(server).to receive(:url).and_return('foo', 'bar')
      end

      it 'raises an error' do
        expect { subject.transfer_output_stage(from_project, to_project, {}) }
          .to raise_error(/Cannot transfer output stage from foo to bar/)
      end
    end

    it 'creates output stage with the same prefix as in the original project' do
      expect(GoodData::AdsOutputStage).to receive(:create)
        .with(hash_including(output_stage_prefix: original_prefix))
      subject.transfer_output_stage(from_project, to_project, {})
    end

    context 'when output stage parameters are specified' do
      let(:options) do
        { ads_output_stage_prefix: prefix,
          ads_output_stage_uri: stage_uri }
      end

      it 'creates output stage with the specified parameters' do
        expect(GoodData::AdsOutputStage).to receive(:create)
          .with(hash_including(output_stage_prefix: prefix, ads: stage_uri))
        subject.transfer_output_stage(from_project, to_project, options)
      end
    end

    context 'when add process already exists' do
      let(:to_add) { double(GoodData::AutomatedDataDistribution) }
      let(:to_output_stage) { double(GoodData::AdsOutputStage) }

      before do
        allow(to_project).to receive(:processes).and_return([process])
        allow(to_project).to receive(:add).and_return(to_add)
        allow(to_output_stage).to receive(:schema)
        allow(to_add).to receive(:output_stage).and_return(to_output_stage)
        allow(to_output_stage).to receive(:schema=)
        allow(to_output_stage).to receive(:output_stage_prefix=)
      end

      it 'sets output stage prefix to the same value as in the original project' do
        expect(to_output_stage).to receive(:output_stage_prefix=).with(original_prefix)
        expect(to_output_stage).to receive(:save)
        subject.transfer_output_stage(from_project, to_project, {})
      end

      context 'when output stage parameters are specified' do
        let(:options) do
          { ads_output_stage_prefix: prefix,
            ads_output_stage_uri: stage_uri }
        end

        it 'sets output stage attributes to the specified values' do
          expect(to_output_stage).to receive(:schema=).with(stage_uri)
          expect(to_output_stage).to receive(:output_stage_prefix=).with(prefix)
          expect(to_output_stage).to receive(:save)
          subject.transfer_output_stage(from_project, to_project, options)
        end
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
