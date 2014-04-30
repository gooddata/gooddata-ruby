---
layout: reference
title:  "Working with objects"
date:   2014-01-19 13:56:00
categories: reference
pygments: true
perex: Learn how to work with individual project objects
---

In this section, we go over basic manipulation of objects within a project.

These objects are manipulated with using the GoodData APIs. Individual API endpoints may have been authored by different individuals at different times, so there may be some variation among them. The Ruby SDK attempts to provide a consistent abstraction layer for these APIs, but in some cases, this abstraction does have variation.

**NOTE:** Some objects in the project are not available yet through the Ruby SDK. Please let us know if you have specific requirements for project objects, and the team can work to prioritize their support.

#Metadata objects

The following project objects are currently supported in the Ruby SDK:

- Report (`GoodData::Report`)
- Report definition (`GoodData::ReportDefinition`)
- Metric (`GoodData::Metric`)
- Fact (`GoodData::Fact`)
- Attribute (`GoodData::Attribute`)
- Project Dashboard (`GoodData::Dashboard`)
- User Filter (N/A)

These objects are served over the same APIs. Below, you can review the available manipulations for these objects.

##Retrieving metadata objects{#retrieve}

Let's first look at how to retrieve the individual objects from server.

###Retrieving list of objects
Retrieve all objects in the currently selected project.

{% highlight ruby %}
reports = GoodData::Report[:all]
{% endhighlight %}

An equivalent statement:
{% highlight ruby %}
reports = GoodData::Report.all
{% endhighlight %}

###Retrieving specific objects
You may retrieve specific objects from the project by project numeric identifier, by internal ID, or by object URI.

####By numeric id
The simplest method is to query by the numeric identifier, which is a number value used internally in the project to identify individual metadata objects.

Numbers are unique within a project and are assigned increasing consecutive integers automatically upon object creation.
**NOTE:** These ids are not unique across projects, so to use them, you must be connected to a specific project.

{% highlight ruby %}
report = GoodData::Report[12]
{% endhighlight %}

You can access the object id from an object:

{% highlight ruby %}
report.obj_id
{% endhighlight %}

####By object identifier

Each object has an internal identifier, which is a string value unique inside the project project. These alphanumeric values can contain also dots. For example, the ID attribute in the Payments dataset may be referenced using the following: `attr.payments.id`.
**NOTE:** These ID are initially assigned based on text values. However, if the display name values change, the internal IDs do not change. You should acquire these internal identifiers via query methods.


You can look the object up by providing an identifier.

{% highlight ruby %}
report = GoodData::Attribute["attr.payments.id"]
{% endhighlight %}

The identifier can be acquired using the following:

{% highlight ruby %}
report.identifier
{% endhighlight %}

####By object uri

You can also provide full URI. This identifier is unique for the object within the entire hosting datacenter.

{% highlight ruby %}
report = GoodData::Report["/gdc/md/pid/12"]
{% endhighlight %}

The URI for a selected object can be accessed using the URI method:

{% highlight ruby %}
report.uri
{% endhighlight %}

####Difference between list and single-object response

**NOTE:** When you query for individual objects, a class is returned through Ruby SDK. When you query for all objects of a specified type, a hash is returned. The API endpoints return only a subset of the available data during collection queries.

If you need to work with full objects, you can use deploy the following method:

{% highlight ruby %}
reports = GoodData::Report.all.map { |data| GoodData::Report[data['link']] }
{% endhighlight %}

The above performs N+1 requests on the API, which may result in slow performance. When using this method, deploy it against the smallest usable collection to speed performance.

###Translating URIs to identifiers

In some cases, you may have the object identifier and need to acquire the datacenter-unique URI. If you know the object type, you can execute a query similar to the following, which is looking for an attribute object identifier:

{% highlight ruby %}
attribute = GoodData::Attribute["attr.payments.id"]
attribute.uri
{% endhighlight %}

However, if you do not know the object type, you can utilize a lower-level method:

{% highlight ruby %}
uris = GoodData::MdObject.identifier_to_uri(id1, id2, id3)
objs = uris.map { |uri| GoodData::MdObject[uri] }
{% endhighlight %}

To learn the specific type of the sub-object, call the root key:

{% highlight ruby %}
obj.category
{% endhighlight %}

You can extend this method to create a specific object. The following creates a new attribute:

{% highlight ruby %}
GoodData::Attribute.new(obj)
{% endhighlight %}

###Other ways of retrieving objects

You can retrieve reports based on tags. Tags are used in projects to organize collections of metrics and reports:

{% highlight ruby %}
reports = GoodData::Report.find_by_tag("some_tag")
{% endhighlight %}

You can retrieve an object based on its title. The following query returns the first object of that name in the selected project. Display names do not need to be unique.

{% highlight ruby %}
report = GoodData::Report.find_first_by_title('My first report')
{% endhighlight %}

##Accesssing object properties
The following properties are accessible for all objects regardless of type:

{% highlight ruby %}
obj.title
obj.summary
obj.deprecated
obj.uri
obj.obj_id
obj.identifier

# Author creation
obj.author
obj.created

# last user to update object
obj.contributor
obj.updated

{% endhighlight %}

Some basic object properties can be specified via API:

{% highlight ruby %}
report.title = "New title"
report.summary = "This is some fancy description"
{% endhighlight %}

**NOTE:** These changes occur locally.

To save your changes to a local object back to the server:

{% highlight ruby %}
report.save
{% endhighlight %}

To delete an object:

**WARNING: Deleting an object cannot be undone.**

{% highlight ruby %}
report.delete
{% endhighlight %}

##Used by using

Metadata within a project is stored internally as a tree.

As a result, you can perform tree-based queries about the edges of the tree. For example, you can query for the objects that are using another object, which translates for example to: "What reports are on a dashboard?"

Here are a couple of helper methods to assist in navigating the tree.

###Getting *used by* or *using* objects


The following methods returns a list of all objects that are used by or are using the selected object. These methods return a transitive closure of all objects dependent/depending on the selected object.
* This approach returns the same structure as the `all` methods discussed at the beginning of this section.

{% highlight ruby %}
report.used_by

report.using
{% endhighlight %}

To retrieve the full object, you must specify the object manually:

{% highlight ruby %}
report.used_by.map { |obj| GoodData::MdObject[obj['link']] }
{% endhighlight %}

###Returning specific type of objects

In some cases, you may wish to retrieve only the objects of a specific category. In place of the specifying an individual object as a parameter, you include the `obj.category` value:

{% highlight ruby %}
report.used_by("attribute")
{% endhighlight %}

If you have retrieved an object already, you can just pass it to the API to retrieve the category value for you:

{% highlight ruby %}
attribute = Attribute[Attribute.all.first["link"]]

report.using(attribute)
{% endhighlight %}

###Asking about specific objects

You can also ask about dependencies of one object on another specific object. This query can be made either with the object uri as a string or with a particular object identifier. This method returns a boolean value.

{% highlight ruby %}
attribute = Attribute[Attribute.all.first["link"]]

report.using?(attribute)
{% endhighlight %}
