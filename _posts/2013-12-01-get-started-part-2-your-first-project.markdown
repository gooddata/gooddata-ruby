---
layout: get-started
title:  "Part II - Your First Project"
date:   2014-01-19 13:56:00
categories: get-started
next_section: get-started/get-started-part-3-model
prev_section: get-started/get-started-part-1-setting-up
pygments: true
perex: Spin up the example project to use in these tutorials. It only takes 5 minutes. Promise.
---

Now that you are all set up let's spin up an example Ruby project which we can use to explore the SDK in the remainder of this tutorial.

###What we want to measure
In any analytics project, success is often determined by identifying what you are trying to measure and building toward those measurements. Since we are developers, we created a simple project about developers to measure their contributions to the code base.

Imagine you have a small development shop with a couple of developers. They crank out lots of code. You also have several repositories for your products. You want to measure how many lines of code each developer creates. You want to track output by time, by repository, and by person. You want to see the number of lines of code each of them has committed.

###Project Model
Here's how the project model looks. Simple enough:

![Model](https://dl.dropboxusercontent.com/s/1y97ziv5anmpn9s/gooddata_devs_demo_model.png?token_hash=AAENC89d8XOfCr9AnyQCrd9vwfhb-bDuYcORQ0AIRP2RQQ)

For each commit, there is related reference information about the source repository, the commitment date, and the developer who made the commitment.

###Spinning it up
Open the command line and start coding. Execute the following to create the `my_test_project` project:

{% highlight ruby %}
gooddata scaffold project my_test_project
{% endhighlight %}

Go to the new project directory:

{% highlight ruby %}
cd my_test_project
{% endhighlight %}

The directory tree looks like the following:

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

For now, don't worry too much about the structure of the files and what they mean; we will get back to them later. Now, build the project:

{% highlight ruby %}
gooddata -U username -P pass -t token project build
{% endhighlight %}

The above `token` value is a GoodData project authentication token, which is required to create an empty project in the GoodData platform.
* If you don't have a project authorization token, please register for our [Developer Trial Program](https://developer.gooddata.com/trial). It is **free**, and you can play around with GoodData for 60 days.

If everything goes well with the build, the command returns a PID, also called a `project_id`. This value must be added to your local project directory structure.

Open the `my_test_project` directory. In your favorite text editor, open the file called, `Goodfile`. It should look the following:

{% highlight ruby %}
{
  "model" : "./model/model.rb",
  "project_id"   : ""
}
{% endhighlight %}

In the file, insert your freshly acquired pid for the `"project_id"` value, as in the following example:

{% highlight ruby %}
{
  "model" : "./model/model.rb",
  "project_id"   : "THIS_IS_YOUR_NEW_PROJECT_ID"
}
{% endhighlight %}

You are done!

To see your new, empty project, please visit [https://secure.gooddata.com/projects.html](https://secure.gooddata.com/projects.html).

##What did you learn
You just generated a template of your first project using the Ruby SDK and then spun up the project. The project still does not contain data or reports, but we will get there.

##Where to go next
You're ready for the next tutorial. Onward!

In next section, we talk in more detail about how the the model is described using the SDK and where in the directory it is stored.