---
layout: tutorial
title:  "Part III - Loading data"
date:   2014-01-19 13:56:00
categories: tutorial
next_section: tutorial/tutorial-part-4-looking-around-project
prev_section: tutorial/tutorial-part-2-model
pygments: true
perex: The logical data model (LDM) defines the facts and attributes in your project, as well as their relationships. Let’s have a look at how to create a project’s LDM using Ruby SDK. Then, we compare this method with other approaches.
---

There are several ways of loading the data. We will explain them later (or you can [peek](/recipe/ref-loading-data) into reference if you are so inclined). For now we will just stick to the simplest one for the problem at hand. First in your terminal run. Remeber to be in `my_test_project` directory

{% highlight ruby %}
gooddata project jack_in
{% endhighlight %}

As we discussed in [getting started](/getting-started), `jack_in` is used for getting into interactive session. Notice that we did not even have to provide project_id because we are in the project directory and it was picked up from the Goodfile. Once in the session type

{% highlight ruby %}
devs = blueprint.get_dataset("devs")
devs.upload("data/devs.csv")

repos = blueprint.get_dataset("repos")
repos.upload("data/repos.csv")

commits = blueprint.get_dataset("commits")
commits.upload("data/commits.csv")

{% endhighlight %}

Done. After a minute or two data should be in the project.

###What is going on?

To dispel the magic a little notice how we are referring to the `blueprint` variable. This is prepared for us by the jack in command who found out the model description in model.rb and built for us an interactive model. Had we written the program ourselves we would have to take of it ourselves. We can query the mode in various ways one of which is asking for specific datasets through `get_dataset` method.

{% highlight ruby %}
devs = blueprint.get_dataset("devs")
{% endhighlight %}

Once we have hold of the dataset. We can load the data into it. One of the ways how we can load data is by providing a path to file.

{% highlight ruby %}
devs.upload("data/devs.csv")
{% endhighlight %}

Now exit the interactive session by typing `exit`.

##What did you learn
You have just seen how easy it is to load data into a project. We will show other ways in the future but it iwll be just a variation on what you have seen.

##Where to go next
Next section we will validate that the data are indeed in the project and create our first metric.