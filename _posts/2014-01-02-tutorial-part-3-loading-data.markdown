---
layout: tutorial
title:  "Part III - Loading data"
date:   2014-01-19 13:56:00
categories: tutorial
next_section: tutorial/tutorial-part-4-looking-around-project
prev_section: tutorial/tutorial-part-2-model
pygments: true
perex: Now that you have created the logical data model for your project, you can now populate it with data from the sample Ruby project.
---

There are several ways of loading the data. For now, we will stick to the simplest approach for the problem at hand.

* We will explain the other methods later. For more information, see [Data Loading Reference](/recipe/ref-loading-data).

First, change to the `my_test_project` directory. Run the following command:

{% highlight ruby %}
gooddata project jack_in
{% endhighlight %}

As discussed in [getting started](/getting-started), the `jack_in` command is used to start an interactive session with a project. Since you are in the project directory, a project ID is not required, as it was extracted from the `Goodfile`.

When the session is initiated, enter the following to upload the three datasets from CSVs stored in the project's `data` directory:

{% highlight ruby %}
devs = blueprint.find_dataset("devs")
devs.upload("data/devs.csv")

repos = blueprint.get_dataset("repos")
repos.upload("data/repos.csv")

commits = blueprint.get_dataset("commits")
commits.upload("data/commits.csv")

{% endhighlight %}

Done. After a minute or two, data should be in the project.

###What is going on?

Notice the `blueprint` variable. This variable is prepared for us by the `jack_in` command, which discovered the model description in `model.rb` and built for us an interactive model.

If we had not used the `jack_in` command, we would have needed to create this reference to an interactive model ourselves. Had we written the program ourselves we would have to take of it ourselves.

The model can be queried in various ways, one of which is to ask for specific datasets through the `get_dataset` method:

{% highlight ruby %}
devs = blueprint.find_dataset("devs")
{% endhighlight %}

After we have acquired the dataset, we can load the data into it. You may reference a path to file:

{% highlight ruby %}
devs.upload("data/devs.csv")
{% endhighlight %}

To exit the interactive session, enter `exit`.

##What did you learn
You have just learned how easy it is to load data into a project. Later, we will reveal other ways, but these are just variations on what you have already learned.

##Where to go next
In the next section, we validate that data is indeed in the project, and we create our first metric.