# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/project_creator'

describe GoodData::Model::ProjectCreator do

  before(:each) do
    # Priority is
    #
    # [cascadeDrops, preserveData],
    # [false, true],
    # [false, false],
    # [true, true],
    # [true, false]
    #
    # The data is ordered in descending priority
    @chunk_a = {
                'updateScript' => {
                  'cascadeDrops' => false,
                  'preserveData' => true,
                  'maqlDdlChunks' => 'a'
                }
              }

    @chunk_b = {
                'updateScript' => {
                  'cascadeDrops' => false,
                  'preserveData' => false,
                  'maqlDdlChunks' => 'b'
                }
              }
    @chunk_c = {
                'updateScript' => {
                  'cascadeDrops' => true,
                  'preserveData' => true,
                  'maqlDdlChunks' => 'c'
                }
              }

    @chunk_d = {
                'updateScript' => {
                  'cascadeDrops' => true,
                  'preserveData' => false,
                  'maqlDdlChunks' => 'd'
                }
              }

    @data = [@chunk_a, @chunk_b, @chunk_c, @chunk_d]

  end

  it 'should pick correct update chunk based on priority' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data)
    expect(chunk).to eq [@chunk_a]
  end

  it 'should pick correct update chunk based on your preference if it is possible to satisfy it' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true,  preserve_data: false})
    expect(chunk).to eq [@chunk_d]
  end

  it 'should pick correct update chunks based on your preference if it is possible to satisfy it and the preference is ambiguous' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true })
    expect(chunk).to eq [@chunk_c, @chunk_d]
  end

  it 'should not pick a chunk if it is not possible to satisfy it based on your preference' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true,  preserve_data: false, unmeetable_condition: true})
    expect(chunk).to eq []
  end
end
