# encoding: UTF-8

# This file shows how the GoodData Ruby API could be used from
# a client code
# 
# Caution: this is far from describing the current functionality!

require 'gooddata'

# Note: this call will store the connection in a thread-local
# variable so this construction and following static method
# calls can be used even in a multi-threaded environment
#
# The connect call is not necessary if credentials are already
# stored in ~/.gooddata (e.g. using bin/gooddata auth:store)

GoodData.connect 'test@example.org', '$3[r37'

# Connect to a specific project
GoodData.project = 'afawtv356b6usdfsdf34vt'

# ... or even during login time
GoodData.connect 'test@example.org', '$3[r37', 'afawtv356b6usdfsdf34vt'

# Get a metadata object
a = Attribute[123]
a = Attribute['attr.country']

# Guess a model from a CSV data set
Model.guess 'data.csv'
# > [ { "type" => "ATTRIBUTE", "title" => "Country" }, ... ]

Model.add_dataset "title" => "Test", "columns" => [
  { "type" => "ATTRIBUTE",  "title" => "Country" }
]
# > Dataset<"dataset.test">

# Populate a data set from a file
Dataset['dataset.test'].load 'data.csv'

# The previous line is actually a short cut for the following call:
p1.datasets['dataset.test'].load GoodData::Source::CsvFile.new 'data.csv'

# Populate a data set from the result of a SalesForce query
Dataset['dataset.test'].load GoodData::Source::SalesForce.new({
  :username => "test@example.org",
  :password => "blahblah",
  :key => "mkjlnlkh845n4lhasdsdagddddddfa",
  :query => "SELECT Id, Name FROM Account"
})

# Get a representation of a specific project
p1 = Project['afawtv356b6usdfsdf34vt']
p2 = Project['/gdc/projects/afawtv356b6usdfsdf34vt']

# Get a specific object by id from a specific project
a = p1.objects[123]
# > Attribute<"attr.country">

# ... or by identifier
a = p1.objects['attr.country']
# > Attribute<"attr.country">

##
# Create a data set from a model
p1.model.add_dataset "title" => "Test", "columns" => [
  { "type" => "ATTRIBUTE",  "title" => "Country" }
]
# > Dataset<"dataset.test">