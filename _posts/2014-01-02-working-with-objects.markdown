---
layout: post
title:  "Working with objects"
date:   2014-01-19 13:56:00
categories: recipe
pygments: true
---

Let's have a look at the basic manipulation of objects. Generally different parts of API were created at different times by different people and using slightly different approach. We strive to provide some unified approach to treating those but sometimes the abstraction is not completely insulating you from what is going under. We try to clean it up as much as we can as we go. Not all objects are also covered we do it on per need basis. Let us know what works for you what does not and what would you like to see next.

#Metadata objects

If we are talking about metadata object in GoodData we mean one of these.
- Report (GoodData::Report)
- Report definition (GoodData::ReportDefinition)
- Metric (GoodData::Metric)
- Fact (GoodData::Fact)
- Attribute (GoodData::Attribute)
- Project Dashboard (GoodData::Dashoard)
- User Filter (N/A)

There are couple of others but you do not need to know about those. All these are served over the same API. So all that I will show you next can be used for any of those regardless of the type.

##Retrieving metadata objects{#retrieve}
Let's first have a look how to get the object from server. First all objects of certain type and then couple of technques how to grab only single object.

###Retrieving list of objects
{% highlight ruby %}
reports = GoodData::Report[:all]
{% endhighlight %}

This is equivalent with
{% highlight ruby %}
reports = GoodData::Report.all
{% endhighlight %}

###Retrieving specific objects
You can also retrieve specific object and there are couple of ways.

####By id
The simplest is to provide the number id. These ids are not unique across projects. This means you have to be signed into specific project. The number is unique in side one project and as of now new ids are assigned as increasing consecutive integer numbers.

{% highlight ruby %}
report = GoodData::Report[12]
{% endhighlight %}

You can access the object id form an object

{% highlight ruby %}
report.obj_id
{% endhighlight %}

####By object identifier

Every object has also something that is called an identifier. Identifier is a string which is again unique inside particular project. They are alphanumeric and can contain also dots. You can look it up by providing an identifier.

{% highlight ruby %}
report = GoodData::Attribute["attr.payments.id"]
{% endhighlight %}

The identifier can be accessed like this

{% highlight ruby %}
report.identifier
{% endhighlight %}

####By object uri

You can also provide full URI. This is not project dependent and the object is uniquely identified in the specific datacenter

{% highlight ruby %}
report = GoodData::Report["/gdc/md/pid/12"]
{% endhighlight %}

URI can be accessed using uri method

{% highlight ruby %}
report.uri
{% endhighlight %}

####Difference between list and single object response
Important thing to note is the difference of content that is returned when you reach for individual objects and all objects of that type. In the former case it returns a class in the latter just a hash. The difference is that the API endpoints return only subset of data during the collection queries. We are not doing anything specific since our opinion is that we in general would make it simpler but much slower. If you need to work with full objects you can use this little trick.

{% highlight ruby %}
reports = GoodData::Report.all.map { |data| GoodData::Report[data['link']] }
{% endhighlight %}

This does N+1 request onthe API which is the basis of what would be slow. If you can definitely filter it to smallest usable collection to speed things up.

###Translating URIs to identifiers

Sometimes you and up having an identifier but you would like to know the URI. If you know what type of the object it is, you can use (let's say in our case it is an attibute)

{% highlight ruby %}
attribute = GoodData::Attribute["attr.payments.id"]
attribute.uri
{% endhighlight %}

But sometimes you do not know the type of the project. In such cases you can leverage the lower level method

{% highlight ruby %}
uris = GoodData::MdObject.identifier_to_uri(id1, id2, id3)
objs = uris.map { |uri| GoodData::MdObject[uri] }
{% endhighlight %}

You can learn of the specific type of the subobject by calling root key

{% highlight ruby %}
obj.category
{% endhighlight %}

Based on this information you can create a specific object. Here we again assume it is an attribute

{% highlight ruby %}
GoodData::Attribute.new(obj)
{% endhighlight %}

###Other ways of retrieving objects

You can retrieve reports based on tags

{% highlight ruby %}
reports = GoodData::Report.find_by_tag("some_tag")
{% endhighlight %}

You can retrieve an object based on a title. This will return the first object of that name since obviously name does not need to be unique.

{% highlight ruby %}
report = GoodData::Report.find_first_by_title('My first report')
{% endhighlight %}

##Accesssing object properties
There are couple properties that are accessible for every type of these object

{% highlight ruby %}
obj.title
obj.summary
obj.deprecated
obj.uri
obj.obj_id
obj.identifier

# who created the object
obj.author
obj.created

# last user who updated object
obj.contributor
obj.updated

{% endhighlight %}

You can set some basic things like summary and title

{% highlight ruby %}
report.title = "New title"
report.summary = "This is some fancy description"
{% endhighlight %}

The changes are happening locally. You can also save the object back to the server

{% highlight ruby %}
report.save
{% endhighlight %}

You can delete it

{% highlight ruby %}
report.delete
{% endhighlight %}

##Used by using
Since metadata about project is one big tree you can also ask about those edges. Which object are used by or using other objects. This translate for example to "what reports are on a dashboard?".

There are couple of helpers to help you getting around

###Getting *used by* or *using* objects

Simplest things you can do is grabbing list of objects that are used by or using certain object. This returns transitive closure of all objects dependent/depending on the object in question.

{% highlight ruby %}
report.used_by

report.using
{% endhighlight %}

This returns the same structure as the all methods discussed at the beginning of the section. If you want to pull in the full objects you have to do it manually.

{% highlight ruby %}
report.used_by.map { |obj| GoodData::MdObject[obj['link']] }
{% endhighlight %}

###Returning specific type of objects
Sometimes all you want is only one type of object say attributes. You can ask SDK to filter them out for you. What you are providing is the `obj.category` value.

{% highlight ruby %}
report.used_by("attribute")
{% endhighlight %}

If you have an object handy you can just pass it and it will extract the category value for you.

{% highlight ruby %}
attribute = Attribute[Attribute.all.first["link"]]

report.using(attribute)
{% endhighlight %}

###Asking about specific object
You can also ask about dependency on particular object. Again you can ask either with uri as a string or a particular object. This method returns a boolean.

{% highlight ruby %}
attribute = Attribute[Attribute.all.first["link"]]

report.using?(attribute)
{% endhighlight %}