---
layout: post
title:  "Part I - Your first project"
date:   2014-01-19 13:56:00
categories: tutorial
next_section: tutorial/tutorial-part-2-model
pygments: true
perex: Spin up a project that you can use for the other tutorials. It will take only 5 minutes. Promise.
---

Before you begin, you must install Ruby and the GoodData SDK and have appropriate access to the GoodData platform and the ability to create or modify projects. See [Getting Started](getting-started) for more details on how to get started.

Welcome. Let's spin up an example project, so you can explore the SDK and see it in action. The project will server as a basis for next parts in tutorial. Since we are developers we created a simple project about developers.

###What we want to measure
In any project, success is often determined by identifying what you are trying to measure.

Imagine you have a small development shop with a couple of developers. They crank out lots of code. You also have several repositories for your products. You want to measure how many lines of code each developer creates. You want to track output by time, by repository and by person. You want to see the number of lines of code each of them committed.

###Model
Here's how the model looks: simple enough to understand the main principles.

![Model](https://dl.dropboxusercontent.com/s/1y97ziv5anmpn9s/gooddata_devs_demo_model.png?token_hash=AAENC89d8XOfCr9AnyQCrd9vwfhb-bDuYcORQ0AIRP2RQQ)

###Spinning it up
Open the command line and start coding. Run the following:

{% highlight ruby %}
gooddata scaffold project my_test_project
{% endhighlight %}

Go to the new project directory:

{% highlight ruby %}
cd my_test_project
{% endhighlight %}

If you look around a little you will see that the directory looks like this

{% highlight bash %}
.
├── Goodfile
├── data
│   ├── commits.csv
│   ├── devs.csv
│   └── repos.csv
└── model
    └── model.rb
{% endhighlight %}

Do not worry too much about the structure of the files and what they mean. We will get back to them later. Now, build the project:

{% highlight ruby %}
gooddata -U username -P pass -t token project build
{% endhighlight %}

The above _token_ value is an authentication token needed to create an empty project in the GoodData Platform. Don't have one? You may register to our [Developer Trial Program](https://developer.gooddata.com/trial). It is **free**, and you can play around with GoodData for 60 days. 

If everything goes well with the build, the command returns a PID, also called a `project_id`. Open the `my_test_project` directory in your favorite text editor. Open the file called, `Goodfile`. It should look the following:

{% highlight ruby %}
{
  "model" : "./model/model.rb",
  "project_id"   : ""
}
{% endhighlight %}

In the file, insert your freshly acquired pid into the empty slot after "project_id", as in the following example:

{% highlight ruby %}
{
  "model" : "./model/model.rb",
  "project_id"   : "THIS_IS_YOUR_NEW_PROJECT_ID"
}
{% endhighlight %}

You are done. Visit [https://secure.gooddata.com/projects.html](https://secure.gooddata.com/projects.html) to see your new project. 

##What did you learn
You just generated a template of your first project using SDK and spun up the project. The project still does not contain data or reports but we will get there.

##Where to go next
You're ready for the next tutorial. Onward! In next section we talk in more detail about how the the model is described using SDK and where in the directory it is stored.