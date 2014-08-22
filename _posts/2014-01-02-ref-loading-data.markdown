---
layout: reference
title:  "Loading data into a project"
date:   2014-01-19 13:56:00
categories: example, general
pygments: true
perex: Whatever you do you need data. Let's look at options how to get them into the project.
---

We strive to make the loading as simple as possible. There are different times and different needs. If you are playing around it is mandatory to be able to load data quickly in an iterative fashion. On the other hand once you deploy you are caring more about speed and correct error messages.

##Warning
Before we start there is one important thing to understand. Whenever you upload a file through APIs as of now it is not enough just to load data. You also have to generate a file that is called a *manifest* and upload it along with the data. Ruby SDK does it for you but it has to have information from which it could generate it and just having the file to load is not enough. What it means when you are using Ruby SDK is to have the model created as described in article [Creating the model](tutorial/tutorial-part-2-model). The model.rb that you use to describe Loading to an arbitrary project without the model description would not work as of now.

##Loading data interactively
If you are playing around with project, creating metrics trying different things it is very helpful if you can load data without a big ceremony.

###Loading data from array

{% highlight ruby %}
gooddata -p PROJECT_ID project jack_in

dataset = blueprint.get_dataset("devs")
dataset.upload([["id", "email"],["1", "john.doe@example.com"]])
{% endhighlight %}

You can load data from an array. The only thing you have to provide is the array of arrays of data. The first line has to contain the names of the colums. The order of colums does not matter but the names has to be in sync with the name defined in the model.

###Loading data from files

The array are useful for having exact per value control but sometimes you just want to load larger amount of data and array become clunky. You can of course load a file. The accepted format is currently CSV. It expects valid CSV with comma as a separator and " as a quote. The lines are separated with a newline. This currently cannot be changed.

{% highlight ruby %}
gooddata -p PROJECT_ID project jack_in

dataset = blueprint.get_dataset("devs")
dataset.upload("/path/to/file.csv")
{% endhighlight %}

You can even provide a file that grabs file from the net. We will provide an automatic authentication for files on our staging area soon.