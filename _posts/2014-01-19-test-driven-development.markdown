---
layout: post
title:  "Test driven development"
date:   2014-01-19 13:56:00
categories: recipe
next_section: recipe/bricks
prev_section: recipe/crunching-numbers
pygments: true
perex: Let's have a look how you can bump project development a little to achieve test driven development of your reports and projects. 
---

Test driven development is a holy grail for many developers. It gives you an additional sense of security and you can rely on the test suite to give you a safety net when you are refactoring and tweaking existing code. Testing reports was always quite hard. Until now.

##The model
Let's reuse the model that we have from [previous chapters](http://sdk.gooddata.com/gooddata-ruby/recipe/model). Just create a file called `model.rb` and put this inside.

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
Let's say that you have some not so simple metric and you want test it to make sure it works as expected. The easiest way to do it is create a testing project and prepare some made up data and then "spin it up". You already know how to create a model and load data. Let's talk about how to define your first test case.

The trick is to use assert_report helper. This means that the report will be executed and if the result will be different it will fail. The helper takes 2 parameters. First is a report definition second is the result expected. Currently it stops on the first failure but this will change soon and we will run all the tests and collect the results.

{% highlight ruby %}
p.assert_report({:top => [{:type => :metric, :title => "Sum Amount"}]}, [["3"]])
{% endhighlight %}

Go ahead and test it

{% highlight ruby %}
gooddata --username joe@example.com --password my_secret_pass --token my_token project build model.rb
{% endhighlight %}

##Production

The way we have it set up right now doesn't force us to use the same metrics to build the report. This is a problem. Ideally, we wanna make sure that the same report in test project is used also in production later. If somebody changes the project because of the business requirements we want the same report to be used in the test and **if something fails we want to know**.

The easiest to achieve this is by extracting the metrics and the model to separate file that can later be used to define the project. You can then reference the same file from your production and testing project and make sure they are built using the same source.

The description might look like this

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

We are externalizing only the metrics but you can hopefully see that it might make sense to do it for the model as well.

#Rinse repeat

If you have any experience with TDD you know that your tests have to run daily to have any effect. This has TBD :-)