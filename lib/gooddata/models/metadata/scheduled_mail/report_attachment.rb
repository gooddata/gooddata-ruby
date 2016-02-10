# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class ReportAttachment
    include GoodData::Mixin::RootKeyGetter
    include GoodData::Mixin::DataGetter

    attr_reader :scheduled_email
    attr_accessor :json

    DEFAULT_OPTS = {
      :formats => %w(pdf xls),
      :exportOptions => {
        :pageOrientation => 'landscape'
      }
    }

    def initialize(scheduled_email, json)
      @scheduled_email = scheduled_email
      @json = json
    end

    # Get export options settings
    #
    # @return [Hash] Export options settings
    def export_options
      data['exportOptions']
    end

    # Set export options settings
    #
    # @param [Hash] new_export_options New export options settings to be set
    # @return [Hash] New export options settings
    def export_options=(new_export_options)
      data['exportOptions'] = new_export_options
    end

    # Get formats
    #
    # @return [Array<String>] List of selected formats
    def formats
      data['formats']
    end

    # Set formats
    #
    # @param [String | Array<String>] new_formats New list of selected formats to be set
    # @return [Array<String>] New list of selected formats
    def formats=(new_formats)
      data['formats'] = new_formats.is_a?(Array) ? new_formats : [new_formats]
    end

    # Get attachment URI
    #
    # @return [String] Attachment URI
    def uri
      data['uri']
    end
  end
end
