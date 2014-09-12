---
layout: guides
title:  "Save/Export Metrics to CSV"
date:   2014-07-09 10:00:00
categories: general
tags:
- metrics
- facts
- attributes
pygments: true
perex: Quickly export metrics from a given project to a CSV document (for use with Excel).
---

Today you will build a quick Ruby script which asks for any project, races to grab a list of all the metrics in human readable form, and then writes them to a CSV.

- Open the Terminal on your Mac (CMD+Spacebar and search for "Terminal").

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/fc171502-7545-426e-b9c8-1532638924e0.png">
<div>
<small>Open up Terminal on your Mac/Linux machine.</small></div>
</div>
</div>

- Download this [script](https://s3.amazonaws.com/xnh/metrics_to_csv.rb) to your *Documents* directory.
- Go back in Terminal and type "cd Documents". Now you are inside of the Documents directory on your Mac you can type "ls" and hit enter to see a list of all of them. One of them is the example script *metrics_to_csv.rb*.
Open the *metrics_to_csv.rb* script in any Text Editor and let's look at few syntax points in Ruby.

- Notice the connect method which uses your login and password to access the GoodData platform. Every script will utitlize this method to insure the correct context.

{% highlight ruby %}
GoodData.connect 'expert.services@gooddata','secretpassword'
{% endhighlight %}

- Go to Terminal again (if you went away from it) and then type.

{% highlight bash %}
ruby metrics_to_csv.rb
{% endhighlight %}

- The script will ask you what project ID you want to export metrics from. Grab a project id at https://secure.gooddata.com. I often to use the My First Project id which you can just copy from the web address. Paste this in your Terminal.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/700e6366-53dd-4aa8-9129-e7145d1207a4.png">
<div>
<small>Pasting the Project ID in Terminal.</small></div>
</div>
</div>


- Enter, “GoodData::Attribute.all” and a list of all the project attributes will be returned. Use space bar to scroll down and press “q” to step back out of the list.
- However, that is a lot of data, select an attributes title from within the terminal window. Any attribute will do and then type...

{% highlight bash %}
GoodData::Attribute.find_by_title(“ATTR-TITLE”).
{% endhighlight %}

- You can also use this to find the attribute by it’s identifier.

{% highlight bash %}
GoodData::Attribute[“ATTR-IDENTIFIER”]
{% endhighlight %}


Type, "exit" to leave "jack_in" and you are done!

