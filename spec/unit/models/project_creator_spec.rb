# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/project_creator'

describe GoodData::Model::ProjectCreator do

  it 'should pick correct update chunk based on priority' do
    # Priority is
    #
    # [cascadeDrops, preserveData],
    # [false, true],
    # [false, false],
    # [true, true],
    # [true, false]
    data = [
      { 'updateScript' => {
        'cascadeDrops' => false,
        'preserveData' => true,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'cascadeDrops' => false,
        'preserveData' => false,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'cascadeDrops' => false,
      'preserveData' => true,
      'maqlDdlChunks' => "a"
    }}


    data = [
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => true,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => false,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'cascadeDrops' => true,
      'preserveData' => true,
      'maqlDdlChunks' => "a"
    }}


    data = [
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => false,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => true,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'cascadeDrops' => true,
      'preserveData' => true,
      'maqlDdlChunks' => "b"
    }}
  end

  it 'should pick correct update chunk based on your preference if it is possible to satisfy it' do
    data = [
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => false,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => true,
        'maqlDdlChunks' => "b"
      }}
    ]

    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data, preference: { cascade_drops: true,  preserve_data: false})
    chunk.should == {
      'updateScript' => {
      'cascadeDrops' => true,
      'preserveData' => false,
      'maqlDdlChunks' => "a"
    }}
  end

  it 'should pick correct update chunk based on your preference if it is not possible to satisfy it' do
    data = [
      { 'updateScript' => {
        'cascadeDrops' => true,
        'preserveData' => true,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'cascadeDrops' => false,
        'preserveData' => true,
        'maqlDdlChunks' => "b"
      }}
    ]

    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data, preference: { cascade_drops: true,  preserve_data: false})
    chunk.should == {
      'updateScript' => {
      'cascadeDrops' => false,
      'preserveData' => true,
      'maqlDdlChunks' => "b"
    }}
  end
end
