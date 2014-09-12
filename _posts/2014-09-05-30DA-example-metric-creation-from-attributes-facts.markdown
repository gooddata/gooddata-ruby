---
layout: guides
title:  "Rapid Metric Creation from Facts/Attributes."
date:   2014-07-09 10:00:00
categories: metric
tags:
- process
- schedule
pygments: true
perex: Create Metrics directly from Facts or Attributes within your project.
---

Today's guide is a quick one which demos how to generate metrics from Facts or Attributes in Ruby. This requires no script to download and is run entirely from the command line in Terminal.

- Open the Terminal on your Mac and let's use the jack_in tool to jump into your project.

{% highlight bash %}
gooddata -p PROJECT_ID -U YOUR-USERNAME -P YOUR-PASSWORD project jack_in
{% endhighlight %}

- Print the list of Facts with this command.

{% highlight ruby %}
GoodData::Fact.all
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/34b2b54c-9980-4391-b943-2c690bd44183.png">
<div>
<small>Copy the identifier of the Fact you want to generate a metric on.</small></div>
</div>
</div>

- Copy the identifier and then let's run the Fact command above targeting that fact specifically.

{% highlight ruby %}
metric = GoodData::Fact['fact.orderlines.price'].create_metric
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/4b6d1880-aff5-4b4d-aae7-f6c9ffc6fe19.png">
<div>
<small>The "sum" metric is by default created from the Fact.</small></div>
</div>
</div>

- You can pass the method object a different type of metric, try using one of these:  *[:sum, :min, :max, :avg, :median]* and then type this command with the new type of metric you would like to create.

{% highlight ruby %}
metric = GoodData::Fact['fact.orderlines.price'].create_metric(:type => :avg)
{% endhighlight %}

- Notice the change in the title of the newly created metric. It should now be prepended by the Fact type you set.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/1405cb7e-880b-4c3e-8ff2-ecff1f9e6e82.png">
<div>
</div>
</div>

- Save the new metric. Remember we defined the metric as an object above.

{% highlight ruby %}
metric.save
{% endhighlight %}

- Now your metric is saved to your project. To actually execute the new metric type.

{% highlight ruby %}
metric.execute
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/36f39d1e-380d-4df3-98d4-11ba2e79d3a7.png">
<div>
<small>The result of the newly created metric. </small></div>
</div>
</div>

And you are set! Have a great day.
