require 'gooddata'

ROW_BASED_DATA = [
  ['tomas@gooddata.com', 'US', 'CZ', 'KZ'],
  ['petr@gooddata.com', 'US'],
  ['petr@gooddata.com','KZ']
]
COLUMN_BASED_DATA_WITH_HEADERS = [
  {
    :login => 'tomas@gooddata.com',
    :country => 'US',
    :age => 14
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'US',
    :age => 19
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'KZ',
    :age => 30
  }
]

COLUMN_BASED_DATA_WITH_HEADERS_AND_NIL_VAL = [
  {
    :login => 'tomas@gooddata.com',
    :country => 'US',
    :age => 14
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'US',
    :age => 19
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'KZ',
    :age => nil
  }
]

COLUMN_BASED_DATA_WITH_HEADERS_AND_EMPTY_VAL = [
  {
    :login => 'tomas@gooddata.com',
    :country => 'US',
    :age => 14
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'US',
    :age => 19
  },
  {
    :login => 'petr@gooddata.com',
    :country => 'KZ',
    :age => ''
  }
]

describe "DSL" do
  it "should pick the values from row based file" do
    results = GoodData::UserFilterBuilder::get_values(ROW_BASED_DATA, {
      :labels => [{:label => "label/34"}]
    })
    results.should == {
      "tomas@gooddata.com"=>[
        {:label=> "label/34", :values=>["US", "CZ", "KZ"], :over => nil, :to => nil}
      ],
     "petr@gooddata.com"=> [
       {:label=> "label/34", :values=>["US"], :over => nil, :to => nil},
       {:label=> "label/34", :values=>["KZ"], :over => nil, :to => nil}
      ]
    }
  end

  it "should pick the values from column based file" do
    results = GoodData::UserFilterBuilder::get_values(COLUMN_BASED_DATA_WITH_HEADERS, {
      :type => :filter,
      :user_column => :login,
      :labels => [{:label => "label/34", :column => :country}]
    })
    results.should == {
      "tomas@gooddata.com"=>[
        {:label => "label/34", :values=>["US"], :over => nil, :to => nil}
      ],
     "petr@gooddata.com"=> [
       {:label=> "label/34", :values=>["US"], :over => nil, :to => nil},
       {:label=> "label/34", :values=>["KZ"], :over => nil, :to => nil}
      ]
    }
  end

  it "should pick the values from column based file with multiple columns" do
    results = GoodData::UserFilterBuilder::get_values(COLUMN_BASED_DATA_WITH_HEADERS, {
      :type => :filter,
      :user_column => :login,
      :labels => [{:label => "label/34", :column => :country}, {:label => "label/99", :column => :age}]
    })
    results.should == {
      "tomas@gooddata.com"=>[
        {:label=> "label/34", :values=>["US"], :over => nil, :to => nil},
        {:label=> "label/99", :values=>[14], :over => nil, :to => nil}
      ],
     "petr@gooddata.com"=> [
       {:label=>"label/34", :values=>["US"], :over => nil, :to => nil},
       {:label=>"label/99", :values=>[19], :over => nil, :to => nil},
       {:label=>"label/34", :values=>["KZ"], :over => nil, :to => nil},
       {:label=>"label/99", :values=>[30], :over => nil, :to => nil}
      ]
    }
  end

  it "should process end to end" do
    result = GoodData::UserFilterBuilder::get_filters(COLUMN_BASED_DATA_WITH_HEADERS, {
      :user_column => :login,
      :labels => [{:label => {:uri => "label/34"}, :column => :country}, {:label => {:uri => "label/99"}, :column => :age}]
    })
    result.should == [
      {
        :login=>"tomas@gooddata.com",
        :filters=> [
          {:label=>{:uri=>"label/34"}, :values=>["US"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[14], :over => nil, :to => nil}
        ]
      },
      {
        :login=>"petr@gooddata.com",
        :filters => [
          {:label=>{:uri=>"label/34"}, :values=>["US", "KZ"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[19, 30], :over => nil, :to => nil}
        ]
      }
    ]
  end

  it "should process end to end nil value should be ignored" do
    result = GoodData::UserFilterBuilder::get_filters(COLUMN_BASED_DATA_WITH_HEADERS_AND_NIL_VAL, {
      :user_column => :login,
      :labels => [{:label => {:uri => "label/34"}, :column => :country}, {:label => {:uri => "label/99"}, :column => :age}]
    })
    result.should == [
      {
        :login=>"tomas@gooddata.com",
        :filters=> [
          {:label=>{:uri=>"label/34"}, :values=>["US"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[14], :over => nil, :to => nil}
        ]
      },
      {
        :login=>"petr@gooddata.com",
        :filters => [
          {:label=>{:uri=>"label/34"}, :values=>["US", "KZ"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[19], :over => nil, :to => nil}
        ]
      }
    ]
  end

  it "should process end to end nil value should be ignored" do
    result = GoodData::UserFilterBuilder::get_filters(COLUMN_BASED_DATA_WITH_HEADERS_AND_EMPTY_VAL, {
      :user_column => :login,
      :labels => [{:label => {:uri => "label/34"}, :column => :country}, {:label => {:uri => "label/99"}, :column => :age}]
    })
    result.should == [
      {
        :login=>"tomas@gooddata.com",
        :filters=> [
          {:label=>{:uri=>"label/34"}, :values=>["US"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[14], :over => nil, :to => nil}
        ]
      },
      {
        :login=>"petr@gooddata.com",
        :filters => [
          {:label=>{:uri=>"label/34"}, :values=>["US", "KZ"], :over => nil, :to => nil},
          {:label=>{:uri=>"label/99"}, :values=>[19, ""], :over => nil, :to => nil}
        ]
      }
    ]
  end

  it "should collect values for every user" do
    data = {
      "tomas" => [
        {:label=>"label/34", :values=>["US"]},
        {:label=>"label/34", :values=>["KZ"]},
        {:label=>"label/99", :values=>[18]},
        {:label=>"label/99", :values=>[20]}
      ],
      "petr" => [
        {:label=>"label/34", :values=>["US"]},
        {:label=>"label/99", :values=>[2]},
        {:label=>"label/99", :values=>[1]}
      ]
    }
    result = GoodData::UserFilterBuilder.reduce_results(data)
    result.should == [{:login=>"tomas",
      :filters=>
       [{:label=>"label/34", :values=>["US", "KZ"], :over => nil, :to => nil},
        {:label=>"label/99", :values=>[18, 20], :over => nil, :to => nil}]},
     {:login=>"petr",
      :filters =>
       [{:label=>"label/34", :values=>["US"], :over => nil, :to => nil},
        {:label=>"label/99", :values=>[2, 1], :over => nil, :to => nil}]}]
  end

  it "should collect values for every label" do
    data = [
      {:label=>"label/34", :values=>["US"]},
      {:label=>"label/34", :values=>["KZ"]},
      {:label=>"label/99", :values=>[18]},
      {:label=>"label/99", :values=>[20]}
    ]
    result = GoodData::UserFilterBuilder.collect_labels(data)
    result.should == [{:label=>"label/34", :values=>["US", "KZ"], :over => nil, :to => nil},
     {:label=>"label/99", :values=>[18, 20], :over => nil, :to => nil}]
    
  end

  it "should collect values" do
    data = [
      {:label=>"label/34", :values=>["US"]},
      {:label=>"label/34", :values=>["KZ"]}
    ]
    results = GoodData::UserFilterBuilder.collect_values(data)
    results.should == ["US", "KZ"]
  end

  it "should translate filters into MAQL filters" do
    data = [
      {
        :login=>"tomas@gooddata.com",
        :filters=> [
          {:label => "label/34", :values=>["US"]},
          {:label => "label/99", :values=>[14]}
        ]
      },
      {
        :login=>"petr@gooddata.com",
        :filters => [
          {:label => "label/34", :values=>["US", "KZ"]},
          {:label=> "label/99", :values=>[19]}
        ]
      }
    ]
    results = data.map do |user_data|
      {
        :login => user_data[:login],
        :maql_filter => user_data[:filters].map { |item| "[#{item[:label]}] IN (#{item[:values].join(', ')})" }.join(" AND ")
      }
    end
    results.should == [
      {:login=>"tomas@gooddata.com", :maql_filter=>"[label/34] IN (US) AND [label/99] IN (14)"},
      {:login=>"petr@gooddata.com", :maql_filter=>"[label/34] IN (US, KZ) AND [label/99] IN (19)"}
    ]
  end
end
