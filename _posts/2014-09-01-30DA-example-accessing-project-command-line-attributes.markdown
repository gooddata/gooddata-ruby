---
layout: guides
title:  "Accessing Projects From Command Line, Browsing Attributes, Facts, and Metrics"
date:   2014-07-09 10:00:00
categories: general
tags:
- metrics
- facts
- attributes
pygments: true
perex: Learn how to print or search for attributes, metrics, facts, using the built in command line tool "jack_in".
---

Learn how to print or search for attributes, metrics, facts using the command line tool “jack_in”.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/693f9e51-b6e6-45d0-8534-320301fdd7fa.png">
<div>
<small>Open up Terminal on your Mac/Linux machine.</small></div>
</div>
</div>

- Open the Terminal on your Mac.
- Make sure you have the GoodData Ruby Gem.

{% highlight bash %}
gem install gooddata
{% endhighlight %}

- Using a project id from any of your projects execute this command.

{% highlight bash %}
gooddata -p PROJECT_ID -U YOUR-USERNAME -P YOUR-PASSWORD project jack_in
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/706f934f-249a-4f97-b287-768ba718adf2.png">
<div>
<small>You now have full access to all of the methods within the SDK so let's start exploring...</small></div>
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

