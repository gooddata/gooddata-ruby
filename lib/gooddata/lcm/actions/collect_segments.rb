# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectSegments < BaseAction
      DESCRIPTION = 'Collect Segments from API'

      PARAMS = define_params(self) do

        description 'Segments to provision'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true
      end

      class << self
        def call(params)
          data_product = params.data_product
          data_product_segments = data_product.segments
          params.gdc_logger.info("Domain segments: #{data_product_segments}")

          if params.segments_filter
            params.gdc_logger.info("Segments filter: #{params.segments_filter}")
            data_product_segments.select! do |segment|
              params.segments_filter.include?(segment.segment_id)
            end
          end

          segments = data_product_segments.pmap do |segment|
            project = nil

            begin
              project = segment.master_project
            rescue RestClient::BadRequest => e
              params.gdc_logger.error "Failed to retrieve master project for segment #{segment.id}. Error: #{e}"
              raise
            end

            raise "Master project for segment #{segment.id} doesn't exist." unless project

            {
              segment_id: segment.segment_id,
              segment: segment,
              development_pid: project.pid,
              driver: project.driver.downcase,
              master_name: project.title,
              segment_master: project,
              uri: segment.uri
            }
          end

          segments.compact!

          # Return results
          {
            results: segments,
            params: {
              segments: segments
            }
          }
        end
      end
    end
  end
end
