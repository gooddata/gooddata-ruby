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

There are two steps to applying the format. The first step is to determine which format you are importing data in; *_Column_* or *_Row_*. The secont step is to 

### Support Formats

The SDK supports two types of CSV, *_Column_* and *_Row_*.

#### Column Format

In the Column format, permissions are broken out into columns. This format is often seen when the user is filtered only on one value of the attribute. Imagine that you have a file like this where each employee's department is defined. This CSV demonstrates the Columns format which department each user can view and each line has the same number of columns.

	user,name,department
	paul@example.com,paul,engineering
	kara@example.com,kara,engineering
	caitlin@example.com,caitlin,marketing
	caitlin@example.com,caitlin,engineering

You would like to filter each of these users based on their deparment.

	paul@example.com -> engineering
	kara@example.com -> engineering
	caitlin@example.com -> engineering, marketing

This can be easily done in this way.

	filters = GoodData::UserFilterBuilder::get_filters(csv, {
	    :login => {:column => ‘user’}
	    :labels => [
	       {:label => {:uri => ATTRIBUTE_LABEL_URI}, :column => ‘department’}
	    ]
	  })

It's import notice that caitlin has 2 values. Notice that in the file she actually has 2 lines. The generator collects the values for you. Login column specification can be omitted if it is the first column. If the file does not have headers, you can specify it like this:

	filters = GoodData::UserFilterBuilder::get_filters(csv, {
	    :headers => false,
	    :login => {:column => 1 }
	    :labels => [
	       {:label => {:uri => ATTRIBUTE_LABEL_URI}, :column => 2}
	    ]
	  })

The columns are specified by the position not name.

#### Row Format

In addition to supporting the column based privelges, you may also have data that looks like this.

	paul@example.com,engineering
	kara@example.com,engineering
	caitlin@example.com,marketing,engineering

Where the user is participating in multiple deparments, or you are filtering users on multiple values. The desired values for the filter are exactly the same as in previous case.

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

## Additional Filters

### Creating Simple Filters
Idea of simple filters is that they are easy enough to remember and are ideal for interactive usage. They cannot cover the whole breath (OVER TO filters etc) but they are for just setting up values and easy enough to remember. It is just an array. The first value is login, the second is the label, the rest is the values. Simple program might look like this.

	attribute = GoodData::Attribute.find_first_by_title('Department')
	label = attribute.label_by_name('Name')
	filters = [["john.doe@gooddata.com", label, "Sales", "Marketing"]]
	GoodData::UserFilterBuilder.execute_mufs(filters)

## Direct input of filters

You can ommit the generator and write the filters directly. There are 2 flavors.

## Additional Options

### Normal or just filter

### Labels specification
Currently you can only specify the label by URI but we want to provide several ways. ADD
identifier
object id
object
Add specification

## Filter resolution and application

resolution and application
Parameters
Ignoring invalid values
By default filter application will fail if you are trying to set up values do not exist in the project. We strongly suggest you do not touch this but if you need to you can switch it off. Invalid values will be ignored. Keep in mind that this might completely change the filter expression in an unintended way.

domain
When applying mandatory user filter there is a feature that filter can be applied for user that is not yet part of the project but will be added later. This will apply all the restrictions immediately and does not introduce any lag that occurs if you add a user and then you try to add the filters. Domain can be easily specified like this

GoodData::UserFilterBuilder.execute_mufs(filters, :domain => GoodData::Domain['domain'])

Remember that a domain can have only one administrator. The user that applies the filter hast to be the domain administrator as well.
