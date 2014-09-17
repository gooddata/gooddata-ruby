---
layout: guides
title:  "Part IV - Looking Around A Project"
date:   2014-01-19 13:56:00
categories: get-started
prev_section: get-started/get-started-part-5-loading-data
next_section: get-started/get-started-part-3-model
pygments: true
perex: "Before we dive into numbers, let's explore the open sandbox of your project through which you can examine almost any aspect of the project: number of users, facts, or attributes, as well as the number of stars in the model."
---

From the project directory, jack in to the project:

{% highlight ruby %}
gooddata -U username -P pass project jack_in
{% endhighlight %}

Verify that you are connected to the project:

{% highlight ruby %}
project = GoodData.project
project.pid
{% endhighlight %}

The following prints a URI, which will take you to the project.

* On a Mac, press command and double click.

{% highlight ruby %}
project.browser_uri
{% endhighlight %}

##Model

Let's have a look at the model.

{% highlight ruby %}
project.datasets.map { |d| d.title }
{% endhighlight %}

The above shows what is currently in the project.

You can compare the above to what is stored in the blueprint:

{% highlight ruby %}
blueprint.datasets.map { |d| d.title }
{% endhighlight %}

The project contains 3 datasets, one of which is actually a date dimension. So, the numbers line up. Great. Let's dig deeper.

###Facts

Let's list all the attributes and facts of the model and print their titles to verify if they are in agreement with our model.

The following displays all facts in the project:

{% highlight ruby %}
facts = GoodData::Fact.all
facts.map { |f| f['title'] }
{% endhighlight %}

The following displays all facts in the blueprint:

{% highlight ruby %}
facts = blueprint.datasets.reduce([]) { |a, e| a + e.facts }
facts.map { |f| f[:name] }
{% endhighlight %}

In both cases, we should see one fact.

###Attributes

You can list all attributes from the project:

{% highlight ruby %}
attrs = GoodData::Attribute[:all, :project => project]
attrs.map { |f| f['title'] }
{% endhighlight %}

And this command lists is all attributes from the blueprint:

{% highlight ruby %}
attrs = blueprint.datasets.reduce([]) { |a, e| a + e.attributes_and_anchors }
attrs.map { |f| f[:name] }
{% endhighlight %}

###Metrics, Reports, Dashboards

You may also look for other objects using the following commands. Right now, our example project contains none of these:

{% highlight ruby %}
dashboards = GoodData::Dashboard[:all, :project => project]
metrics = GoodData::Metric[:all, :project => project]
reports = GoodData::Report[:all, :project => project]
{% endhighlight %}

We will start creating these in the next part.

##What did you learn
We verified that the model has been created, and we are able to inspect it. For other options in examining a project, see the Reference Guide.

##Where to go next
In next section, we will look at how to compute some of the metrics.