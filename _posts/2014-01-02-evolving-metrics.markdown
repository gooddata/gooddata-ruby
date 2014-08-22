---
layout: reference
title:  "Evolving metrics and reports"
date:   2014-01-19 13:56:00
categories: example metrics
pygments: true
perex: Let's have a look at magic you can do with metrics and soon whole reports. How to transform them and change them so you can never have to delete and redo another report form scratch. Let's walk through what is possible and look at couple of real world scenarios.
---

##Warning
This is an advanced topic and we expect that you understand following things perfectly. Understand what is metric, fact, etc. You understand what is the difference between attribute and label and how are they related in model. Especially this is very important for fully grasping this topic.

##MAQL
MAQL is very useful language and it helps keep reports terse and flexible compared to pure SQL. UI does a great job at insulating you from lower level details of some implementation decisions but if you try doing something useful you have to deal with the whole complexity. Until now.

##Readable metrics
Imagine grabbing metric

{% highlight ruby %}
m = GoodData::Metric[259]
{% endhighlight %}

You can print the expression that came over the wire

{% highlight ruby %}
m.expression
{% endhighlight %}

This will return something along the lines of

{% highlight ruby %}
SELECT SUM([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/204]) WHERE [/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/58]= [/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/58/elements?id=3577]
{% endhighlight %}

As you can see this is not ideal. SDK provides additional method to make this more reaable

{% highlight ruby %}
m.pretty_expression
{% endhighlight %}

Which will return for our particular metric
{% highlight ruby %}
SELECT SUM([Lines changed]) WHERE [Date (Committed on)]= [10/17/1909]
{% endhighlight %}

Much better. You can easilly produce a list of metrics with a readable interpretation something like this.

{% highlight ruby %}
metrics = GoodData::Metric.all :full => true
File.open('list_of_metrics.txt', 'w') do |f|
  metrics.each do |metric|
    f.puts("#{metric.title} - #{metrics.pretty_expression}")
  end
end
{% endhighlight %}

##contain?

It is useful in many cases to ask if certain metric contains some other object. From the expression above we see that the metric contains fact with id 204. Let's test that

{% highlight ruby %}
f = GoodData::Fact[204]
m.contain?(f)
{% endhighlight %}

Obvious question is how this compares to `used_by` and `using`. The difference is that these two checks objects that are directly or even indirectly used. `contain?` will check only object itself. What you want depends on the situation.

##replace, replace_value
Often times a customer comes and asks us. We created 200 reports for our marketing department. They keep an eye on a specific product so every report is along "something WHERE Product = 'chair'". Suddenly the strategy changed. The chair is no longer hip and they would like to focus on 'table'. Here is the problem. Redoing every report is not an easy task. If you count 5 mins for each report and you have a report you are looking at 2 days of work. Or you can use `replace` and `replace_value`.

###replace_value

Let's take our above example. We want to exchange filtered value on all metrics. First we need to find out what attribute a product is.

{% highlight ruby %}
product_attribute = GoodData::Attribute.find_first_by_title('Product')
{% endhighlight %}

Let's grab all metrics that we would like to change
{% highlight ruby %}
metrics = GoodData::Metric.all :full => true
{% endhighlight %}

Last step is replacing the value
{% highlight ruby %}
metrics.each do |metric|
  metric.replace_value(product_attribute.primary_label, 'chair', 'label')
  metric.save
end
{% endhighlight %}

Congratulations. You just saved yourself 1.98 days.

###replace
Replace works very similarly but it is for echanging objects. You can update metric with another metric, attribute, fact etc. SDK does not pay too much attention to which objects you are swapping so the results might not be what you want to so be careful. Let's have a look at a simple example

{% highlight ruby %}
metric.pretty_expression
=> "SELECT COUNT([Product])"
metric.expression
=> "SELECT COUNT([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/70])"
{% endhighlight %}

Now we know that the product has `object_id=70`. Let's say that you want to exchange it for a different attribute with id `89`.

{% highlight ruby %}
product_attribute = GoodData::Attribute[70]
other_attribute = GoodData::Attribute[89]
metric.replace(product_attribute, other_attribute)
metric.save
{% endhighlight %}