# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class LocalizeMetricFormats < BaseAction
      DESCRIPTION = 'Localize Metric Formats'

      PARAMS = define_params(self) do
        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: false

        description 'Localization query'
        param :localization_query, instance_of(Type::StringType), required: false
      end

      class << self
        def get_localization_groups(params)
          dwh = params.ads_client
          localization_query = params['localization_query']
          return [nil] if dwh.nil? || localization_query.nil?
          data = dwh.execute_select(localization_query)
          localization_groups = {}
          clients = data.map{|row| row[:client_id]}.uniq
          clients.each do |client|
            formats = {}
            data.select{|row| row[:client_id] == client}.each {|row| formats[row[:tag]] = row[:format]}
            lg_id = formats.keys.sort.inject(''){|hash,k| hash + k + formats[k]}
            localization_groups[lg_id] ||= {:id => lg_id,:formats => formats}
            localization_groups[lg_id][:clients] ||= []
            localization_groups[lg_id][:clients] << client
          end
          localization_groups.values
        end

        def call(params)
          updated_clients = params.synchronize.map{|segment| segment.to.map{|client| client[:client_id] }}.flatten.uniq
          data_product = params.data_product
          data_product_clients = data_product.clients
          localization_groups = get_localization_groups(params)
          log = []
          localization_groups.peach do |localization_group|
            localization_group[:clients].peach do |client_id|
              next unless updated_clients.include?(client_id)
              client = data_product_clients.find{|c| c.id == client_id}
              metrics = client.project.metrics.to_a
              localization_group[:formats].each do |k,v|
                log << {:tag => k,:format => v,:client => client_id}
                metrics_to_be_localized = metrics.select{|metric| metric.tags.include?(k)}
                metrics_to_be_localized.each do |metric|
                  metric.format = v
                  metric.save
                end
              end
            end
          end
          log
        end
      end
    end
  end
end
