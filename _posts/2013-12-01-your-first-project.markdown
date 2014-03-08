---
layout: post
title:  "Your first project"
date:   2014-01-19 13:56:00
categories: recipe
next_section: recipe/model
pygments: true
perex: Let's spin up a project that will be the base for other tutorials. It will take only 5 mins. Promise.
---

Welcome. Let's spin up an example project that so you can explore and see SDK in action. It's super simple. Since you are probably a developer we created simple project about developers.

###What we want to measure
Imagine you have a small dev shop. You have a couple of developers. They crank out code. You also have several repositories for your products. You want to measure how many lines of code each of the devs create. You wanna be able to track it by time, by repository and by person. You want to see how many lines of code they committed.

###Model
This is how the model looks. Simple enough to understand main principles and how Ruby SDK works.

![Model](https://dl.dropboxusercontent.com/s/1y97ziv5anmpn9s/gooddata_devs_demo_model.png?token_hash=AAENC89d8XOfCr9AnyQCrd9vwfhb-bDuYcORQ0AIRP2RQQ)

###Spinning it up
Open the command line and start coding. I assume you already have GoodData Ruby SDK installed and working on your computer. Run

{% highlight ruby %}
    gooddata scaffold project my_test_project
{% endhighlight %}

go to the new project directory

{% highlight ruby %}
    cd my_test_project
{% endhighlight %}

and build project by running

{% highlight ruby %}
    gooddata -U username -P pass -t token project build
{% endhighlight %}

The _token_ above is well know authentication token that you need to create an empty project in GoodData Platform. Don't have one? Register to our [Developer Trial Program](https://developer.gooddata.com/trial). It is **free** and you can play around with GoodData for 60 days. If everything goes ok it will give you a PID also called a `project_id`. Open the `my_test_project` directory in your favorite text editor and open file called Goodfile. It should look like this

{% highlight ruby %}
    {
      "model" : "./model/model.rb",
      "project_id"   : ""
    }
{% endhighlight %}

Put your freshly acquired pid into an empty slot after "project_id". See the example below

{% highlight ruby %}
    {
      "model" : "./model/model.rb",
      "project_id"   : "HERE_COMES_YOUR NEW_TOKEN"
    }
{% endhighlight %}

You are done. If you go to [https://secure.gooddata.com/projects.html](https://secure.gooddata.com/projects.html) you should be able to see your new project! You are now fully prepared to the next tutorial. It's time to move forward! 
