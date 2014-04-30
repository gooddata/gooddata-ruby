---
layout: post
title:  "Part IV - Looking around project"
date:   2014-01-19 13:56:00
categories: tutorial
prev_section: tutorial/tutorial-part-3-loading-data
next_section: tutorial/tutorial-part-5-computing
pygments: true
perex: The capabilities of SDK does not end with defining a model. Before we dive into numbers let's explore the open sandbox of project. You can look at almost any aspect of the project. How many users are there, do we have more facts or attributes, how many stars is in the model and many more.
---

So you have a project with data but before we start crunching numbers. Let's look around. As usual start an interactive session in your terminal.

{% highlight ruby %}
gooddata project jack_in
{% endhighlight %}

You can verify that we are looking at the project.

{% highlight ruby %}
GoodData.project.pid
{% endhighlight %}

By running

{% highlight ruby %}
GoodData.project.browser_uri
{% endhighlight %}

You can print a URI which will take you to the project (On mac just press command and double click)

##Model
Let's have a look at the model.

{% highlight ruby %}
GoodData.project.datasets.map { |d| d.title }
{% endhighlight %}

This is what we have in the project. If you compare to what comes from blueprin

{% highlight ruby %}
blueprint.datasets.map { |d| d.title }
{% endhighlight %}

You will see that we have 3 datasets. One from the above is actually a date dimension. So we have the same number. Great. Let's dig deeper.

Let's list all the attributes and facts and print their titles so we can see if it is in agreement with our model. This is what is in the project.

###Facts

{% highlight ruby %}
facts = GoodData::Fact.all
facts.map { |f| f['title'] }
{% endhighlight %}

And this is in the blueprint
{% highlight ruby %}
facts = blueprint.datasets.reduce([]) { |a, e| a + e.facts }
facts.map { |f| f[:name] }
{% endhighlight %}

In both cases we should see on fact.

###Attributes
You can do something similar for attributes.

{% highlight ruby %}
attrs = GoodData::Attribute.all
attrs.map { |f| f['title'] }
{% endhighlight %}

And this is in the blueprint
{% highlight ruby %}
attrs = blueprint.datasets.reduce([]) { |a, e| a + e.attributes_and_anchors }
attrs.map { |f| f[:name] }
{% endhighlight %}

###Metrics, Reports, Dashboards

You can try to look for other objects but as of now there should be none of those types

{% highlight ruby %}
GoodData::Dashboard.all
GoodData::Metric.all
GoodData::Report.all
{% endhighlight %}

No worries, we will remedy the situation in the next part.

##What did you learn
You have seen that we really created the model and we can inspect it. If you like to see what else you could do. Have a look at the reference guide.

##Where to go next
In next section we will look at how to compute some of the metrics