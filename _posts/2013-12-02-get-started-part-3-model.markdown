---
layout: guides
title:  "Part III - Creating A Data Model"
date:   2014-01-19 13:56:00
categories: get-started
next_section: get-started/get-started-part-4-looking-around-project
prev_section: get-started/get-started-part-2-your-first-project
pygments: true
perex: The logical data model (LDM) defines the facts and attributes in your project, as well as their relationships. Let’s have a look at how to create a project’s LDM using Ruby SDK. Then, we compare this method with other approaches.
---

There are several ways to express and create a data model in GoodData. The most prominent way is to use the LDM Modeler, a visual modeler included in the CloudConnect package. The visual approach has clear advantages, but there are some drawbacks.<br/>

- A **logical data model** is the graphical representation of the objects in the project and their relationships to each other. The underlying physical data model is the set of tables and structures used to store the data in the datastore. It is created from the logical data model by the platform automatically. You do not have to interact with the physical data model at all. For more information, see [Building a Model in GoodData tutorial](https://developer.gooddata.com/getting-started/).

The visual development method is **not repeatable**, **not programmable**, and **not text-based**. As a result, this method does not fit well into SCM and all other fancy tools that developers like to use.

This section provides an alternative to building visually through CloudConnect Designer. In the previous section, we spun up a simple project with a simple data model. Let's have a look on how it is defined using the Ruby SDK.

##The Data Model

The model we created looks like the following:

![Model](https://dl.dropboxusercontent.com/s/1y97ziv5anmpn9s/gooddata_devs_demo_model.png?token_hash=AAENC89d8XOfCr9AnyQCrd9vwfhb-bDuYcORQ0AIRP2RQQ).

##The Code

Let's explore how the model is defined in Ruby. In the project directory, open the file called `model/model.rb`. You should see the following code:

{% highlight ruby %}
model = GoodData::Model::ProjectBuilder.create("my_test_project") do |p|
  p.add_date_dimension("committed_on")

  p.add_dataset("repos") do |d|
    d.add_anchor("repo_id")
    d.add_label("name", :reference => "repo_id")
  end

  p.add_dataset("devs") do |d|
    d.add_anchor("dev_id")
    d.add_label("email", :reference => "dev_id")
  end

  p.add_dataset("commits") do |d|
    d.add_fact("lines_changed")
    d.add_date("committed_on", :dataset => "committed_on")
    d.add_reference("dev_id", :dataset => 'devs', :reference => 'dev_id')
    d.add_reference("repo_id", :dataset => 'repos', :reference => 'repo_id')
  end

end
{% endhighlight %}

Hopefully, the above model is fairly self-explanatory in identifying the datasets, facts, attributes, and other elements of the data model.

- If you need a refresher on modeling terminology, please refer to [Building a Model in GoodData tutorial](https://developer.gooddata.com/getting-started/).

Let's review the elements of the model.

###Defining the model

The top-level statement is the following:

{% highlight ruby %}
GoodData::Model::ProjectBuilder.create("my_test_project") do |p|
.
.
.
end
{% endhighlight %}

This command instructs the SDK to create a template (in the Ruby SDK, it is called a **blueprint**) for the project with title `my_test_project`.

- It expects the block.
- Inside the block, the project builder is accessible as variable `p`.

###Defining a date dimension

Within the block, the first command is the following:

{% highlight ruby %}
p.add_date_dimension("committed_on")
{% endhighlight %}

This command creates a standard GoodData date dimension.

- The sole parameter passed to it is the name or identifier for the dimension. This identifier is used to refer to the dimension in later stages of the model definition.

###Defining a dataset

The following section contains three datasets. The first one looks like the following:

{% highlight ruby %}
p.add_dataset("repos") do |d|
  d.add_anchor("id")
  d.add_label("name", :reference => "id")
end
{% endhighlight %}

As with the date dimension, we pass it one parameter, which serves as a technical name.

- The title value, which is visible in the UI, is automatically derived from the technical name.
- To dataset, we are providing a block. Inside the block, a dataset builder is available as variable `d`.

####Defining fields within a dataset
Inside the block, we define the fields in the dataset. The first one is an anchor:

{% highlight ruby %}
d.add_anchor("id")
{% endhighlight %}

The anchor object is very similar to the attribute object. An **attribute** is a field containing some qualitative content (string or numeric values), which is used to break down reporting values.
* The difference between an anchor and an attribute is that an **anchor** can be referenced by other datasets. An anchor is very similar to a primary key in the database world.
* We provided the technical name as the first parameter.

The second column in the dataset is a label:

{% highlight ruby %}
d.add_label("name", :reference => "id")
{% endhighlight %}

A **label** is a set of data that applies to an attribute or an anchor. For example, `Social Security #` could be a label for `Name`, since it uniquely identifies an individual.
* In its definition, the label contains a name and a reference to the column for which it is a label.
* The `:reference =>` uses the technical name as a reference.

The next two datasets are variations on the previous dataset. Let's examine the differences only.

####Adding a fact

Here, you can see how a fact is added. Here, just the name of the fact is provided:

{% highlight ruby %}
d.add_fact("lines_changed")
{% endhighlight %}

####Adding a reference to another element

On the next line is a reference to a date dimension, which was the first thing created in the blueprint. We use the id when we are defining a reference to that dimension:

{% highlight ruby %}
d.add_date("committed_on", :dataset => "committed_on")
{% endhighlight %}

Compare the above to the definition of the reference from Commit to Dev. The above attempts to express the basic relationship. The devs dataset was defined as the following:

{% highlight ruby %}
p.add_dataset("devs") do |d|
  d.add_anchor("id")
  d.add_label("email", :reference => "id")
end
{% endhighlight %}

The reference to it looks like the following. Notice that the reference includes identification of the technical identifier for the reference, the dataset and anchor field of the referenced field.

{% highlight ruby %}
p.add_dataset("devs") do |d|
  d.add_reference("dev_id", :dataset => 'devs', :reference => 'id')
end
{% endhighlight %}

You reference the dataset through the technical name and a reference to point out the anchor.

**NOTE:** In the future, this strict reference may not be required, as the anchor will be available as a lookup.

##Some Conventions

Please observe the following rules:

* We are trying to apply conventions to the modeling process. Please follow them to reduce keystrokes. You may always override them.
* In all cases where you enter a name, the value is a **string used to create a technical name in gooddata (an identifier)**. This strict is applied using the API. The user-visible name (called the **title**) will be inferred if it is not explicitly provided. The inferring process is simple; the Ruby SDK expect you to provide a name in the snake case.
* Typically in ruby, names like `close_date`, `opportunity_dimension` and more are translated into human-readable strings like `Close date` or `Opportunity dimension`. If you do not like the inferred title, you may specify it directly using code `:title => "My own title"`.
* Names are also used as reference names in the data model. For example, the date is using the name of the `committed_on` dimension, and the `dev_id` reference is used to reference developers.

##What did you learn
We just walked through a small yet complete project model. Outside of CloudConnect Designer, there are other ways to create a data model, and the Ruby SDK method may be advantageous. You should understand how a basic model is structured and what is required to build your own.

##Where to go next
In next section, we will explore how to load data into your project.
