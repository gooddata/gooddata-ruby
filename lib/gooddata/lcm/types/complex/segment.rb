# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../base_type'

require_relative 'complex'

module GoodData
  module LCM2
    module Type
      class SegmentType < ComplexType
        CATEGORY = :complex

        PARAMS = define_type(self) do
          description 'Segment ID'
          param :segment_id, instance_of(Type::StringType), required: true

          description 'PID of Development Project'
          param :development_pid, instance_of(Type::StringType), required: true

          description 'Storage Driver'
          param :driver, instance_of(Type::StringType), required: false, default: 'pg'

          description 'Master Project Name'
          param :master_name, instance_of(Type::StringType), required: true

          description 'Production Tag Names'
          param :production_tags, array_of(instance_of(Type::StringType)), required: false
        end

        def check(value)
          BaseType.check_params(PARAMS, value)
        end
      end
    end
  end
end
