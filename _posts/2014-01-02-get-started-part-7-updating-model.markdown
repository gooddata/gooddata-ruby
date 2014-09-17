---
layout: guides
title:  "Part VII - Updating A Model"
date:   2014-01-19 13:56:00
categories: get-started
prev_section: get-started/get-started-part-6-computing
next_section: get-started/get-started-part-8-next-steps
pygments: true
perex: It is a sad fact that majority of time on any software project is spent maintaining it and changing it then on first iteration getting it out of the door. Let's see what happens when a customer asks us for updating the model. The question is not if this happens but when.
---

In this section you will learn how to edit the labels on a data set by changing the a *blueprint* of your project. A *blueprint* is the programatic representation of your GoodData project and can be found in model/model.rb of your scaffolded "my_test_project" which you created in Part III.

Recall *model.rb*...

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

Notice how there are three datasets.

- repos: 1 label "name", and 1 anchor pointing to "repo_id".
- devs: 1 label "email", and 1 anchor pointing to "dev_id".
- commits: 1 fact "lines_changed", 1 date "committed_on", 2 references "dev_id" and "report_id"

Let's assume you want to add development comments to your data model. As an example let's say that your CSV looks like this.

{% highlight bash %}
dev_id,email,comment
1,tomas@gooddata.com,This tutorial is so much fun.
2,petr@gooddata.com,Please update the tutorial.
3,jirka@gooddata.com,The new parallel format is much faster.
{% endhighlight %}

To add the comments field all you have to do is add the relevant label and reference to the dataset.

*model.rb*
{% highlight ruby %}
  ...

  p.add_dataset("devs") do |d|
    d.add_anchor("dev_id")
    d.add_label("email", :reference => "dev_id")
    d.add_label("comment", :reference => "dev_id") # Add
  end

  ...
{% endhighlight %}

Now let's jack in to the project and update the model.

{% highlight bash %}
gooddata -p YOUR_PROJECT_ID -U YOUR_USERNAME@gooddata.com -P YOUR_PASSWORD project jack_in
{% endhighlight %}

And then update the blueprint.

{% highlight ruby %}
blueprint = eval(File.read('./model/model.rb')).to_blueprint
{% endhighlight %}

Finally, upload your changes to the platform.

{% highlight ruby %}
model = GoodData::Model.upload_data('./data/devs.csv', blueprint, 'devs')
{% endhighlight %}






