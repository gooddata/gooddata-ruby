---
layout: post
title:  "Part II - Creating a data model"
date:   2014-01-19 13:56:00
categories: tutorial
next_section: recipe/crunching-numbers
prev_section: recipe/your-first-project
pygments: true
perex: The logical data model (LDM) defines the facts and attributes in your project, as well as their relationships. Let’s have a look at how to create a project’s LDM using Ruby SDK. Then, we compare this method with other approaches.
---

There are several ways to express and create a data model in GoodData. The most prominent way is to use the LDM Modeler, a visual modeler included in the CloudConnect package. The visual approach has clear advantages, but there are some drawbacks.

Visual development is **not repeatable**, **not programmable**, and **not text-based**, which makes it hard to fit into SCM and all other fancy tools developers are learned to use.

In last section we spun up a simple model. Let's have a look on how it is defined using the Ruby SDK.

##The Data Model

The model we created looks like this:

![Model](https://dl.dropboxusercontent.com/s/1y97ziv5anmpn9s/gooddata_devs_demo_model.png?token_hash=AAENC89d8XOfCr9AnyQCrd9vwfhb-bDuYcORQ0AIRP2RQQ). 

##The Code

Last time we said that we will look into how model is defined. Open the file called `model/model.rb`, and you should see the following code:

{% highlight ruby %}
GoodData::Model::ProjectBuilder.create("my_test_project") do |p|
  p.add_date_dimension("committed_on")

  p.add_dataset("repos") do |d|
    d.add_anchor("id")
    d.add_label("name", :reference => "id")
  end

  p.add_dataset("devs") do |d|
    d.add_anchor("id")
    d.add_label("email", :reference => "id")
  end

  p.add_dataset("commits") do |d|
    d.add_fact("lines_changed")
    d.add_date("committed_on", :dataset => "committed_on")
    d.add_reference("dev_id", :dataset => 'devs', :reference => 'id')
    d.add_reference("repo_id", :dataset => 'repos', :reference => 'id')
  end

end
{% endhighlight %}

Hopefully, the above model is fairly self-explanatory in terms what is a dataset, fact or attribute. If you need a refresher on modeling terminology, please refer to [Building a Model in GoodData tutorial](https://developer.gooddata.com/getting-started/).

Let's walk over the pieces.

First we have

{% highlight ruby %}
GoodData::Model::ProjectBuilder.create("my_test_project") do |p|
.
.
.
end
{% endhighlight %}

This tells the SDK to create a template (or in SDK lingo it is called blueprint) for the project with title `my_test_project`. It expects the block. Inside the block the project builder is accessible as variable `p`.

Next we have

{% highlight ruby %}
p.add_date_dimension("committed_on")
{% endhighlight %}

This will create a standard GoodData date dimension. Note that we pass it one parameter that is the name or identifier. We will use this name to refer to the dimension in later stages of the model.

Next section contains three datasets. The first one looks like this.

{% highlight ruby %}
p.add_dataset("repos") do |d|
  d.add_anchor("id")
  d.add_label("name", :reference => "id")
end
{% endhighlight %}

Note that similarly as with date dimension we pass it one parameter which serves as a technical name. The title (that is visible in the UI) is automatically derived from the technical name. Also note that to dataset we are providing a block. Inside the block a dataset builder is available as variable d. Inside the block we are defining fields in the dataset. The first one is an anchor.

{% highlight ruby %}
d.add_anchor("id")
{% endhighlight %}

Anchor is very similar to attribute (attribute is something that has some qualitative content and is used to break the numbers by). The difference is that other datasets can refer to the anchor. It is very similar to primary key from database world. Note that again we provided the technical name as the first parameter. Second column is a label

{% highlight ruby %}
d.add_label("name", :reference => "id")
{% endhighlight %}

The label is a different label for an attribute or an anchor so it has to have a name and also a reference to the column it is label for. The `:reference =>` uses the technical name as a reference.

You can see that other datasets are variations on the previous dataset. Let's cover only the differences. Here you can see how a fact is added. Again just name has to be provided.

{% highlight ruby %}
d.add_fact("lines_changed")
{% endhighlight %}

On the next line a reference to a date dimension is created. Remember that we defined a date dimension as the first thing in the blueprint

{% highlight ruby %}
p.add_date_dimension("committed_on")
{% endhighlight %}

Notice that we are now using the id when we are defining a reference to that dimension.

{% highlight ruby %}
d.add_date("committed_on", :dataset => "committed_on")
{% endhighlight %}

Compare the above to the definition of the reference from Commit to Dev. This basically tries to express the relationship. Every commit has a developer. We defined devs dataset like this.

{% highlight ruby %}
p.add_dataset("devs") do |d|
  d.add_anchor("id")
  d.add_label("email", :reference => "id")
end
{% endhighlight %}

Notice how we define the reference.

{% highlight ruby %}
p.add_dataset("devs") do |d|
  d.add_reference("dev_id", :dataset => 'devs', :reference => 'id')
end
{% endhighlight %}

You reference the dataset through the technical name again and using a reference to point out the anchor. This will probably not be strictly needed in the future since anchor can be looked up.

##Some Conventions

Please note the following rules:

* We are trying to apply conventions to the modeling process. Follow them to reduce the keystrokes. You may always override them.
* In all cases where you enter a name, the value is a **string used to create a technical name in gooddata (an identifier)** using the API. The user-visible name (called the title) will be inferred, if it is not explicitly provided. The inferring process is simple. The Ruby SDK expect you to provide a name in the snake case. Typically in ruby, names like **close_date**, **opportunity_dimension** and more are translated into human-readable strings like **Close date** or **Opportunity dimension**. If you do not like the inferred title, you can specify it directly using code `:title => "My own title"`. 
* Names are also used as reference names in the data model. Notice how the date is using the name of the **committed_on** dimension, and the **dev_id** reference is used to reference developers.
s

##What did you learn
We just walked through a full fledged even though small project model. You should understand what other ways are there to create one and why this one might be advantageous. You should understand how the model is structured and understand how to put together your own.

##Where to go next
In next section we will look into how to get data int your project.