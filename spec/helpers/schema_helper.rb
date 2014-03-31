# encoding: UTF-8

require 'gooddata/models/metadata/schema'

module SchemaHelper
  COLUMNS = [
    {:type => :anchor, :name => 'cp', 'title' => 'CP', 'folder' => 'test'},
    {:type => :attribute, :name => 'a1', 'title' => 'A1', 'folder' => 'test'},
    {:type => :attribute, :name => 'a2', 'title' => 'A2', 'folder' => 'test'},
    {:type => :date, :name => 'event', 'title' => 'Event', 'folder' => 'test'},
    {:type => :fact, :name => 'f1', 'title' => 'F1', 'folder' => 'test'},
    {:type => :fact, :name => 'f2', 'title' => 'F2', 'folder' => 'test'},
  ]

  SCHEMA = GoodData::Model::Schema.new :name => 'test', :title => 'test', :columns => COLUMNS
end