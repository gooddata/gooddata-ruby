---
layout: guides
title:  "Tagging Multiple Metrics"
date:   2014-06-10 10:56:00
categories: example
pygments: true
perex: Imagine you want to do some changes in your projects that would take a lot of manual work. Let's use Ruby SDK to avoid this boring work.
---

Imagine a simple use case. You are working on a GoodData Project and so you are creating some new metrics and reports. Let's say you've been working hard last two days and created 54 new metrics. Imagine a situation - your teammate or your customer would like to see those amazing reports in action. No problem. But, wait a second. 

_How to easily recognize those reports?_

I forgot to mark them somehow. No **folder**, no **tag**. Let's add tag to every metric that I've created. But it is like 54 metrics, right? You probably don't want to be clicking for the next 2 hours again and again manually. So, how to solve this problem?

_Let's write a script that will do it within a few seconds!_ 

Thanks to GoodData Ruby SDK there is an easy way (as far as you know a little bit of Ruby) you can help yourself. First of all let's connect to the GoodData Platform:

{% highlight ruby %}
require "gooddata"

GoodData.connect("username","password")
GoodData.use("your-project-id")
{% endhighlight %}

We are connected to the project so let's iterate over all metrics in our Project, select all metrics that has been created by myself during the last 2 days and add “new_functionality” tag to it. Check how easy it is:

{% highlight ruby %}
metrics = GoodData::Metric.all(:full => true)

metrics.each do |m|
  user = GoodData.get(m.meta["contributor"])
  created = DateTime.parse(m.meta["created"])
  if (user["accountSetting"]["login"] == "my_user@gooddata.com" and created > DateTime.now - 2.days)
    m.tags += "new_functionality"
    m.save
  end
end
{% endhighlight %}

Finally let's print all metrics we've tagged:

{% highlight ruby %}
GoodData::Metric.find_by_tag('new_functionality').each do |m|
  puts m["title"]
end
{% endhighlight %}
It is so simple, isn't it? 

If you think it is better to do it manually imagine that **you've already created 10 clones of this project** for your customer and so you would need to change 540 metrics. How does it feel now? 