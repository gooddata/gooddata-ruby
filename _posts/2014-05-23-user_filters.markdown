---
layout: reference
title:  "User filters"
date:   2014-01-19 13:56:00
categories: reference
pygments: true
perex: User filters are a powerful feature allowing to set up per user filters. API is fairly complex but SDK does a ton of heavy lifting to make it a cake.
---

##Before you start
Before you start it would be great to get up to speed on what user filters are and what are typical use cases. There is also a short tutorial on how to set them up as part of SDK demo project.

##Architecture
Way it works.
To provide maximum flexibility the architecture is proivided in 2 layers.
Provide a picture
# Filter generation
# Filter resolution and application

The first one is here to help you generate the filters to a format that the second layer can understand. This layer is optional and can be superseded by your hands or you can use one of the provided generators or roll out your own. The second turns the filters into a format that the API can understand and resolves what needs to be updated in the project. There are 2 flavors of this layer. One sets up Variables the other one Mandatory User filters. You can read about the differences here. There are not so many differences on the interface layer and since mandatory filters are much mode widely applied we will not point the differences between those 2 too much.

## Generators
There are 2 main ideas of generators.
* Generator should try not to force the user to change the data that comes out of the system. Generator should be able to work with it with as little changes as possible. We tried to include generators for typical situations
* Separation of platform specific data and customer data. This means that we do not expect a URI of label to be part of the data because it is unlikely to come from the customer and it would violate the first principle.

Ok let's delve to generators. There are 2 flavors

### Column wise generator
Imagine that you have a file like this. CSV which has headers. Each line has the same number of columns.

	user,name,department
	paul@example.com,paul,engineering
	kara@example.com,kara,engineering
	caitlin@example.com,caitlin,marketing
	caitlin@example.com,caitlin,engineering

You want to set these values

	paul@example.com -> engineering
	kara@example.com -> engineering
	caitlin@example.com -> engineering, marketing

You can easily achieve this like this

	filters = GoodData::UserFilterBuilder::get_filters(csv, {
	    :login => {:column => ‘user’}
	    :labels => [
	       {:label => {:uri => ATTRIBUTE_LABEL_URI}, :column => ‘department’}
	    ]
	  })

Notice that caitlin has 2 values. Notice that in the file she actually has 2 lines. The generator collects the values for you. Login column specification can be omitted if it is the first column. If the file does not have headers. You can specify it

	filters = GoodData::UserFilterBuilder::get_filters(csv, {
	    :headers => false,
	    :login => {:column => 1 }
	    :labels => [
	       {:label => {:uri => ATTRIBUTE_LABEL_URI}, :column => 2}
	    ]
	  })

The columns are specified by the position not name. Otherwise everything else holds up. 

### Row wise generator

Imagine you have a file like this. Note that each line has different number of values so it does not make sense to have headers.

	paul@example.com,engineering
	kara@example.com,engineering
	caitlin@example.com,marketing,engineering

The desired values for the filter are exactly the same as in previous case.

	paul@example.com -> engineering
	kara@example.com -> engineering
	caitlin@example.com -> engineering, marketing

You can achieve this with the following code.

	filters = GoodData::UserFilterBuilder::get_filters(csv, {
	    :labels => [
	       {:label => {:uri => ATTRIBUTE_LABEL_URI}}
	    ]
	  })

The row base mode is activated when you have only one label (which should naturally be the case) and that one does not have specified the column. Login has to be the first thing in the file.

## Direct input of filters

You can ommit the generator and write the filters directly. There are 2 flavors.

### Simple
Idea of simple filters is that they are easy enough to remember and are ideal for interactive usage. They cannot cover the whole breath (OVER TO filters etc) but they are for just setting up values and easy enough to remember. It is just an array. The first value is login, the second is the label, the rest is the values. Simple program might look like this.

	attribute = GoodData::Attribute.find_first_by_title('Department')
	label = attribute.label_by_name('Name')
	filters = [["john.doe@gooddata.com", label, "Sales", "Marketing"]]
	GoodData::UserFilterBuilder.execute_mufs(filters)

### Normal or just filter

Add specification

#### Labels specification
Currently you can only specify the label by URI but we want to provide several ways. ADD
identifier
object id
object

## Filter resolution and application

resolution and application
Parameters
Ignoring invalid values
By default filter application will fail if you are trying to set up values do not exist in the project. We strongly suggest you do not touch this but if you need to you can switch it off. Invalid values will be ignored. Keep in mind that this might completely change the filter expression in an unintended way.

domain
When applying mandatory user filter there is a feature that filter can be applied for user that is not yet part of the project but will be added later. This will apply all the restrictions immediately and does not introduce any lag that occurs if you add a user and then you try to add the filters. Domain can be easily specified like this

GoodData::UserFilterBuilder.execute_mufs(filters, :domain => GoodData::Domain['domain'])

Remember that a domain can have only one administrator. The user that applies the filter hast to be the domain administrator as well.
