---
layout: post
title:  "Adding a field to a dataset"
date:   2013-06-16 13:56:00
categories: recipe
pygments: true
perex: A customer wants to add a new attribute to a dimension to a working project. In BAM, it's a 10-minute job.
---

Suppose your project works as expected, but you need to add a field. In BAM, the basic steps are as follows: 
* You must acquire the data for that field. 
* You must create a field in your sink.

Suppose your tap looks like the following:

{% highlight json %}
{
   "source" : "salesforce"
  ,"object" : "User"
  ,"id" : "user"
  ,"incremental" : true
  ,"fields" : [{
      "name" : "Id"
    },{
      "name" : "Name"
    }]
}
{% endhighlight %}

The sink looks like the following:

{% highlight json %}
{
  "target" : "gooddata",
  "id": "owner_dim",
  "gd_name": "opp_owner",
  "fields": [{
    "type": "attribute",
    "name": "id",
    "meta": "Id"
  }, {
    "type": "label",
    "for": "id",
    "name": "name",
    "meta": "Name"
  }]
}
{% endhighlight %}

Let's do the most trivial case where you grab additional field from the source, which is Salesforce in this case. 
* Another case: you want to do some processing, which is available in the specific tasks of other recipes.

####Tap

First, let's add the field to the source tap. Let's say we want to grab a field called *Region*.

{% highlight json %}
{
   "source" : "salesforce"
  ,"object" : "User"
  ,"id" : "user"
  ,"incremental" : true
  ,"fields" : [{
      "name" : "Id"
    }, {
      "name" : "Name"
    },{
      "name" : "Region"
    }]
}
{% endhighlight %}

The tap is updated. 

*NOTE:* It is important to download the fields correctly for storage. For more information, see (Limitations of Event Store)[/recipe/2013/06/16/limitation-of-event-store.html]. 

####Sink

In the sink, you can simply add a reference to the attribute and then call a BAM function to update the dataset. 
* *NOTE:* For more complex manipulations, such as creating new datasets and moving items between datasets, please make your modifications in CloudConnect LDM Modeler.

The update to the sink looks like the following:

{% highlight json %}
{
  "target" : "gooddata",
  "id": "owner_dim",
  "gd_name": "opp_owner",
  "fields": [{
    "type": "attribute",
    "name": "id",
    "meta": "Id"
  }, {
    "type": "label",
    "for": "id",
    "name": "name",
    "meta": "Name"
  }, {
    "type": "attribute",
    "name": "region",
    "meta": "Region"
  }]
}
{% endhighlight %}

The field named *region* of type=attribute has been added to the sink and is sourced from the metadata field *Region*.

To update the model:

{% highlight json %}
bam model_sync
{% endhighlight %}

*NOTE:* You must have CL tool installed.

If the command is successful, the model is updated.

To run the ETL:
{% highlight json %}
bam generate
{% endhighlight %}