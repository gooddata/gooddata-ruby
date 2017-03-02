# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class AutomatedDataDistribution < Rest::Resource
    attr_writer :output_stage

    def output_stage
      if @output_stage
        @output_stage
      else
        url = project.uri.gsub('/gdc/projects/', '/gdc/dataload/projects/') + '/outputStage'
        data = project.client.get(url)
        # TODO: We need to pass ADS but how to get it?
        self.output_stage = GoodData::AdsOutputStage.create(data.merge({project: project, client: project.client}))
        output_stage
      end
    end

    def initialize(project)
      self.project = project
    end

    def process
      GoodData::Process[:all, project: project, client: project.client].find do |p|
        p.type == :dataload
      end
    end

    def create_output_stage(ads, opts = {})
      self.output_stage = GoodData::AdsOutputStage.create({ ads: ads, project: project, client: project.client }.merge(opts))
      output_stage
    end
  end
end
