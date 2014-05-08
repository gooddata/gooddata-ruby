# encoding: UTF-8

require 'gooddata/models/project_creator'

describe GoodData::Model::ProjectCreator do

  it 'should say it contains a depending metric if it does' do
    # response['projectModelDiff']['updateScripts']
    
    data = [
      { 'updateScript' => {
        'preserveData' => true,
        'cascadeDrops' => false,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'preserveData' => false,
        'cascadeDrops' => false,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'preserveData' => true,
      'cascadeDrops' => false,
      'maqlDdlChunks' => "a"
    }}


    data = [
      { 'updateScript' => {
        'preserveData' => true,
        'cascadeDrops' => true,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'preserveData' => false,
        'cascadeDrops' => true,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'preserveData' => true,
      'cascadeDrops' => true,
      'maqlDdlChunks' => "a"
    }}


    data = [
      { 'updateScript' => {
        'preserveData' => false,
        'cascadeDrops' => true,
        'maqlDdlChunks' => "a"
      }},
      { 'updateScript' => {
        'preserveData' => true,
        'cascadeDrops' => true,
        'maqlDdlChunks' => "b"
      }}
    ]
    chunk = GoodData::Model::ProjectCreator.pick_correct_chunks(data)
    chunk.should == {
      'updateScript' => {
      'preserveData' => true,
      'cascadeDrops' => true,
      'maqlDdlChunks' => "b"
    }}

  end
end
