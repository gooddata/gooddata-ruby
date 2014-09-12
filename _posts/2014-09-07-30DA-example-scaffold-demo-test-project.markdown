---
layout: guides
title:  "Scaffold a Demo/Test Project Including Data"
date:   2014-07-09 10:00:00
categories: project
tags:
- project
- scaffold
pygments: true
perex: Create a small demo project with example data and data model a feature built in to the GoodData gem.
---

The CTO of Grapefruit Computer is waiting, you have his attention for moments. How will you help track data representing the iFruit? Wouldn't it be nice if you could spin up a project in a second with users, model, demo and data on the spot?

Enter scaffold, my second favorite feature of the GoodData Ruby SDK (right behind jack_in).

- With this command you will set up a project, users, a model, a basic graph, and demo data.

{% highlight bash %}
gooddata scaffold project my_test_project
{% endhighlight %}

What the GoodData gem has set up is a framework which includes items we will cover later. For now, what you need to know is you have a complete copy of a genuine GoodData project outside of CloudConnect built programmatically. This is big a deal.

- Open Terminal and change directories ("cd my_test_project") into the project and we will push it to GoodData's servers. You will need your GoodData DEV token, if you have not set one up you can grab it here. Your dev token is not the project id.

{% highlight bash %}
gooddata -U YOUR_USERNAME@gooddata.com -P YOUR_PASSWORD -t YOUR_TOKEN project build
{% endhighlight %}

- Make sure you notice you did not have to login to build a test project, you can be standing right there and on their make show them how fast they can grab a project framework without even having to set up an account. Just "gem install gooddata", then "gooddata scaffold project my_test_project"; two commands in any terminal anywhere and GoodData is on their machine.

- Just to show you, within Terminal go ahead and jack_in to the project you just created (or go to secure.gooddata.com) to demo it. Make sure you are inside the my_test_project directory.

{% highlight bash %}
gooddata -U YOUR-USERNAME -P YOUR-PASSWORD project jack_in
{% endhighlight %}

And you are done!