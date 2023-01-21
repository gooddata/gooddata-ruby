# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true, preserve_data: false })
    expect(chunk).to eq [@chunk_d]
  end

  it 'should pick correct update chunks based on your preference if it is possible to satisfy it and the preference is ambiguous' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true })
    expect(chunk).to eq [@chunk_c, @chunk_d]
  end

  it 'should not pick a chunk if it is not possible to satisfy it based on your preference' do
    expect do
      GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { cascade_drops: true, preserve_data: false, unmeetable_condition: true })
    end.to raise_error
  end

  it 'should pick correct update chunks based on new parameter "allow_cascade_drops" in your preference' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { allow_cascade_drops: false })
    expect(chunk).to eq [@chunk_a]
  end

  it 'should pick correct update chunks based on new parameter "keep_data" in your preference' do
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { keep_data: false })
    expect(chunk).to eq [@chunk_a, @chunk_b]
  end

  it 'should raise error when mixing new parameters with the old ones in your preference' do
    expect do
      GoodData::Model::ProjectCreator.pick_correct_chunks(@data, update_preference: { allow_cascade_drops: true, cascade_drops: false })
    end.to raise_error('Please do not mix old parameters (:cascade_drops, :preserve_data) with the new ones (:allow_cascade_drops, :keep_data).')
  end

  describe '#fallback_to_hard_sync' do
    before(:each) do
      @chunk_hard_sync_true_false = {
        'updateScript' => {
          'cascadeDrops' => true,
          'preserveData' => false,
          'fallbackHardSync' => true,
          'maqlDdlChunks' => 'cascadeDrop=true;preserveData=false'
        }
      }

      @chunk_hard_sync_false_false = {
        'updateScript' => {
          'cascadeDrops' => false,
          'preserveData' => false,
          'fallbackHardSync' => true,
          'maqlDdlChunks' => 'cascadeDrop=false;preserveData=false'
        }
      }
    end

    describe '#With old parameters cascade_drops and preserve_data' do
      it 'should pick correct update chunks with cascade_drops=true and preserve_data=true in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { cascade_drops: true, preserve_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { cascade_drops: true, preserve_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with cascade_drops=true and preserve_data=false in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { cascade_drops: true, preserve_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { cascade_drops: true, preserve_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with cascade_drops=false and preserve_data=true in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { cascade_drops: false, preserve_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with cascade_drops=false and preserve_data=false in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { cascade_drops: false, preserve_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore cascade_drops and preserve_data in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore preserve_data in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { cascade_drops: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { cascade_drops: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore cascade_drops in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { preserve_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { preserve_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should raise error when failed to pick chunk with missing cascade_drops and preserve_data in your preference' do
        expect do
          GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { cascade_drops: false, preserve_data: false, fallback_to_hard_sync: true })
        end.to raise_error('Synchronize LDM cannot proceed. Adjust your update_preferences and try again. Available chunks with preference: {:cascade_drops=>true, :preserve_data=>false, :fallback_hard_sync=>true}')
      end
    end

    describe '#With new parameters allow_cascade_drops and keep_data' do
      it 'should pick correct update chunks with allow_cascade_drops=true and keep_data=true in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { allow_cascade_drops: true, keep_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { allow_cascade_drops: true, keep_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with allow_cascade_drops=true and keep_data=false in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { allow_cascade_drops: true, keep_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { allow_cascade_drops: true, keep_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with allow_cascade_drops=false and keep_data=true in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { allow_cascade_drops: false, keep_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with allow_cascade_drops=false and keep_data=false in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { allow_cascade_drops: false, keep_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore allow_cascade_drops and keep_data in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore keep_data in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { allow_cascade_drops: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_true_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { allow_cascade_drops: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should pick correct update chunks with ignore allow_cascade_drops in your preference' do
        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { keep_data: false, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]

        chunk = GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_false_false], update_preference: { keep_data: true, fallback_to_hard_sync: true })
        expect(chunk).to eq [@chunk_hard_sync_false_false]
      end

      it 'should raise error when failed to pick chunk with missing allow_cascade_drops and keep_data in your preference' do
        expect do
          GoodData::Model::ProjectCreator.pick_correct_chunks_hard_sync([@chunk_hard_sync_true_false], update_preference: { allow_cascade_drops: false, keep_data: false, fallback_to_hard_sync: true })
        end.to raise_error('Synchronize LDM cannot proceed. Adjust your update_preferences and try again. Available chunks with preference: {:cascade_drops=>true, :preserve_data=>false, :fallback_hard_sync=>true}')
      end
    end
  end
end
