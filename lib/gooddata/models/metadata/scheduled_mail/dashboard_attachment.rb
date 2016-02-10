# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class DashboardAttachment
    include GoodData::Mixin::RootKeyGetter
    include GoodData::Mixin::DataGetter

    attr_reader :scheduled_email
    attr_accessor :json

    DEFAULT_OPTS = {
      :allTabs => 1,
      :tabs => []
    }

    def initialize(scheduled_email, json)
      @scheduled_email = scheduled_email
      @json = json
    end

    # Get all tabs flag
    #
    # @return [Fixnum] All dashboard tabs?
    def all_tabs
      data['allTabs']
    end

    # Set all tabs flag
    #
    # @param [String | Fixnum] new_all_tabs New value of all_tabs flag to be set
    # @return [Fixnum] New value of all_tabs flag
    def all_tabs=(new_all_tabs)
      data['allTabs'] = new_all_tabs.to_i
    end

    # Get selected tabs
    #
    # @return [Array<String>] List of selected tabs
    def tabs
      data['tabs']
    end

    # Set selected tabs
    #
    # @param [Array<String>] new_tabs New list of selected tabs to be set
    # @return [Array<String>] New list of selected tabs
    def tabs=(new_tabs)
      data['tabs'] = new_tabs
    end

    # Get attachment URI
    #
    # @return [String] Attachment URI
    def uri
      data['uri']
    end
  end
end
