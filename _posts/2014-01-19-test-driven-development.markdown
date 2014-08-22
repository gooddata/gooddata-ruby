---
layout: post
title:  "Test-driven Development"
date:   2014-01-19 13:56:00
categories: example general
pygments: true
perex: Let's have a look how you can enhance project development to achieve test-driven development of your reports and projects. 
---

Often called a “holy grail” of development, test-driven development delivers an additional sense of security, as the test suite is your safety net when you are refactoring and tweaking existing code. 

In this example, a report is developed using test-driven methodology and is validated and delivered much more rapidly.


##The Data Model

Let's use the model described in [this page](http://sdk.gooddata.com/gooddata-ruby/recipe/model). Create a file called `model.rb` and put the following in it:

{% highlight ruby %}
GoodData::Model::ProjectBuilder.create("gooddata-ruby test #{Time.now.to_i}") do |p|
  p.add_date_dimension("closed_date")

  p.add_dataset("users") do |d|
    d.add_anchor("id")
    d.add_label("name", :reference => 'id')
  end

  p.add_dataset("regions") do |d|
    d.add_anchor("id")
    d.add_attribute("name")
  end

  p.add_dataset("opportunities") do |d|
    d.add_fact("amount")
    d.add_date("closed_date", :dataset => "closed_date")
    d.add_reference("user_id", :dataset => 'users', :reference => 'id')
    d.add_reference("region_id", :dataset => 'regions', :reference => 'id')
  end

  p.add_metric({
    "title": "Sum Amount",
    "expression": "SELECT SUM(#\"amount\") + 1",
    "extended_notation": true
  })

  p.upload([["id", "name"],
            ["1", "Tomas"],
            ["2", "Petr"]], :dataset => 'users')

  p.upload([["id", "name"],
            ["1", "Tomas"],
            ["2", "Petr"]], :dataset => 'regions')

end
{% endhighlight %}

##The Test

Let's say that you have a complex metric, and you wish to verify that it works as expected. 

The easiest way: create a testing project and prepare some dummy data before spinning up the project. You have already stepped through the process of creating your model and loading it with data. For more information, see [this page](http://sdk.gooddata.com/gooddata-ruby/recipe/model).

Let's talk about how to define your first test case.The trick is to use assert_report helper. 

This method executes the report and including an expected result as a parameter. The first parameter is a report definition, and the second one is the expected result. If the generated result does not match the second parameter, the assertion fails.

Currently, this method stops on the first failure. In a future release, all tests will be executed before results are delivered back to you.

Execute assert_report:

{% highlight ruby %}
p.assert_report({:top => [{:type => :metric, :title => "Sum Amount"}]}, [["3"]])
{% endhighlight %}

Go ahead and test it:

{% highlight ruby %}
gooddata --username joe@example.com --password my_secret_pass --token my_token project build model.rb
{% endhighlight %}

##Production


The current configuration of our project does not force us to use the same metrics to build the report. This is a problem. 

Ideally, we must ensure that the same report used in the test project is also used later in production. If somebody changes the project due to changes in business requirements, we want the same report to be used in the test and **if something fails, we want to know**.

The easiest way: extract the metrics and the model to separate files that can later be used to define the project. You can then reference the same file from your production and testing project to ensure that they are built from the same source.

The description might look like the following:

{% highlight ruby %}
GoodData::Model::ProjectBuilder.create("gooddata-ruby test #{Time.now.to_i}") do |p|
  p.add_date_dimension("closed_date")

  p.add_dataset("users") do |d|
    d.add_anchor("id")
    d.add_label("name", :reference => 'id')
  end

  p.add_dataset("regions") do |d|
    d.add_anchor("id")
    d.add_attribute("name")
  end

  p.add_dataset("opportunities") do |d|
    d.add_fact("amount")
    d.add_date("closed_date", :dataset => "closed_date")
    d.add_reference("user_id", :dataset => 'users', :reference => 'id')
    d.add_reference("region_id", :dataset => 'regions', :reference => 'id')
  end

  p.load_metrics('https://bit.ly/gd_demo_1_metrics')

  p.upload([["id", "name"],
            ["1", "Tomas"],
            ["2", "Petr"]], :dataset => 'users')

  p.upload([["id", "name"],
            ["1", "Tomas"],
            ["2", "Petr"]], :dataset => 'regions')

  p.upload([["amount", "closed_date", "user_id", "region_id"],
            ["1", "2001/01/01", "1", "1"],
            ["1", "2001/01/01", "1", "2"]], :dataset => 'opportunities')

  p.assert_report({:top => [{:type => :metric, :title => "Sum Amount"}]}, [["3"]])

end
{% endhighlight %}

In the above, we are externalizing only the metrics. You can see how it might make sense to externalize the model, as well.

#Rinse, repeat

If you have any experience with test-driven development, you know that your tests must run daily to maintain integrity. This scheduling step is TBD :-)

