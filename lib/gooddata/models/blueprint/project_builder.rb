# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'dashboard_builder'
require_relative 'schema_builder'

module GoodData
  module Model
    class ProjectBuilder
      attr_accessor :data

      class << self
        def create_from_data(blueprint, title = 'Title')
          pb = ProjectBuilder.new(title)
          pb.data = blueprint.to_hash
          pb
        end

        def create(title, _options = {}, &block)
          pb = ProjectBuilder.new(title)
          block.call(pb)
          pb
        end
      end

      def initialize(title, options = {})
        @data = {}
        @data[:title] = title
        @data[:datasets] = []
        @data[:date_dimensions] = []
        @data.merge(options)
      end

      def add_date_dimension(id, options = {})
        dimension = {
          type: :date_dimension,
          urn: options[:urn],
          id: id,
          title: options[:title]
        }

        data[:date_dimensions] << dimension
      end

      def add_dataset(id, options = {}, &block)
        builder = GoodData::Model::SchemaBuilder.new(id, options)
        block.call(builder) if block
        fail 'Dataset has to have id defined' if id.blank?
        datasets = data[:datasets]
        if datasets.any? { |item| item[:id] == id }
          ds = datasets.find { |item| item[:id] == id }
          index = datasets.index(ds)
          stuff = GoodData::Model.merge_dataset_columns(ds, builder.to_hash)
          datasets.delete_at(index)
          datasets.insert(index, stuff)
        else
          datasets << builder.to_hash
        end
      end

      def add_computed_attribute(id, options = {})
        metric = options[:metric].identifier
        attribute = options[:attribute].identifier
        buckets = options[:buckets].sort_by do |bucket|
          bucket.length == 2 ? bucket.last : 1 / 0.0
        end

        last_bucket = buckets.pop
        relations = buckets.map do |bucket|
          name, up_to = bucket
          "when {#{metric}} <= #{up_to} then {#{id}?\"#{name}\"}"
        end
        relations += ["when {#{metric}} > #{buckets.last.last} then {#{id}?\"#{last_bucket.first}\"} else {#{id}?\"\"} end"]
        relations = ["to {#{attribute}} as case #{relations.join(', ')}"]

        add_dataset(id.sub('attr.', 'dataset.'), options) do |d|
          d.add_anchor(id, options.merge(relations: relations))
          d.add_label(id.sub('attr.', 'label.'), reference: id, default_label: true)
        end
      end

      def to_json(options = {})
        eliminate_empty = options[:eliminate_empty] || false

        if eliminate_empty
          JSON.pretty_generate(to_hash.reject { |_k, v| v.is_a?(Enumerable) && v.empty? })
        else
          JSON.pretty_generate(to_hash)
        end
      end

      def to_blueprint
        GoodData::Model::ProjectBlueprint.new(to_hash)
      end

      def to_hash
        data
      end
    end
  end
end
