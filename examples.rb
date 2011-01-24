# This file shows a bunch of random ways how the GoodData Ruby API
# should be invokable. 
# Caution: this is far from describing the current functionality!

require 'gooddata'

# Optional if credentials are already stored in ~/.gooddata
# using bin/gooddata auth:store
#
# Note: this call will store the connection in a thread-local
# variable so this construction and following static method
# calls can be used even in a multi-threaded environment
GoodData.connect 'test@example.org', '$3[r37'

# Get a representation of a specific project
p1 = Project['afawtv356b6usdfsdf34vt']
p2 = Project['/gdc/projects/afawtv356b6usdfsdf34vt']

# Get a specific object by id
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

p1.datasets['dataset.test'].load_file 'data.csv' # just a short cut for GoodData::Source::CsvFile
p1.datasets['dataset.test'].load GoodData::Source::CsvFile.new 'data.csv' # the same as above

p1.datasets['dataset.test'].load GoodData::Source::SqlQuery.new {
  :url => "mysql://localhost/test",
  :username => "root",
  :password => "mysqlpassword",
  :query => "SELECT * FROM invoice"
}

#####################################################################
# or set project context (thread-local)
#
GoodData.project = 'afawtv356b6usdfsdf34vt'

# ... or even during login time
GoodData.connect 'test@example.org', '$3[r37', 'afawtv356b6usdfsdf34vt'

a = Attribute[123]
a = Attribute['attr.country']

Model.guess 'data.csv'
# > [  ... ]

Model.add_dataset "title" => "Test", "columns" => [
  { "type" => "ATTRIBUTE",  "title" => "Country" }
]
# > Dataset<"dataset.test">

Dataset['dataset.test'].load 'data.csv'

Dataset['dataset.test'].load GoodData::Source::SalesForce.new {
  :username => "test@example.org",
  :password => "blahblah",
  :key => "mkjlnlkh845n4lhasdsdagddddddfa",
  :query => "SELECT Id, Name FROM Account"
}