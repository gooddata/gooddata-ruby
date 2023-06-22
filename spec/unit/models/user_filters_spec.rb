# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

def check_filters(filters)
  filters.count.should eq(2)
  filter = filters.first
  filter[:login].should eq("john.doe@example.com")
  filter[:filters].count.should eq(1)
  filter[:filters].first[:values].count.should eq(4)
  filter[:filters].first[:values].should eq(["USA", "Czech Republic", "Uganda", "Slovakia"])
  filter = filters.last
  filter[:login].should eq("jane.doe@example.com")
  filter[:filters].count.should eq(1)
  filter[:filters].first[:values].count.should eq(1)
end

describe 'User filters implementation' do
  it "should create user filters from a file using row based approach" do
    filters = GoodData::UserFilterBuilder.get_filters(
      './spec/data/line_based_permissions.csv',
      :labels => [{ :label => "/gdc/md/lu292gm1077gtv7i383hjl149sva7o1e/obj/2719" }]
    )
    check_filters(filters)
  end

  it "should create user filters from a file using column based approach" do
    filters = GoodData::UserFilterBuilder.get_filters(
      './spec/data/column_based_permissions.csv',
      :labels => [{ :label => "/gdc/md/lu292gm1077gtv7i383hjl149sva7o1e/obj/2719", :column => 'region' }]
    )
    check_filters(filters)
  end

  it "should treat empty like nil, empty value has to be enclosed in quotes" do
    filters = GoodData::UserFilterBuilder.get_filters(
      './spec/data/column_based_permissions.csv',
      :labels => [
        { :label => "some_label", :column => 'region' },
        { :label => "other_label", :column => 'department' }
      ]
    )
    filters.first[:filters].last[:values].count.should eq(3)
  end

  it "should be able to specify columns by number" do
    filters = GoodData::UserFilterBuilder.get_filters(
      './spec/data/column_based_permissions2.csv',
      :user_column => 2,
      :labels => [
        { :label => "some_label", :column => 0 },
        { :label => "other_label", :column => 1 }
      ]
    )
    filters.first[:filters].last[:values].count.should eq(2)
  end

  it "should be able to specify columns by name" do
    filters = GoodData::UserFilterBuilder.get_filters(
      './spec/data/column_based_permissions2.csv',
      :user_column => 'login',
      :labels => [
        { :label => 'some_label', :column => 'region' },
        { :label => 'other_label', :column => 'department' }
      ]
    )
    filters.first[:filters].last[:values].count.should eq(2)
  end

  it "should normalize simplified filters" do
    filters = [
      [
        "svarovsky+gem_tester@gooddata.com",
        "/gdc/md/zndbmx87kh69vk8liods10mwxesaxn3k/obj/213",
        "tomas@gooddata.com",
        "jirka@gooddata.com"
      ]
    ]
    GoodData::UserFilterBuilder.normalize_filters(filters).should eq([
      {
        :login => "svarovsky+gem_tester@gooddata.com",
        :filters => [
          {
            :label => "/gdc/md/zndbmx87kh69vk8liods10mwxesaxn3k/obj/213",
            :values => ["tomas@gooddata.com", "jirka@gooddata.com"]
          }
        ]
      }
    ])
  end
end
