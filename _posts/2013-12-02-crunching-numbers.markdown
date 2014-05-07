---
layout: reference
title:  "Crunching numbers"
date:   2014-01-19 13:56:00
categories: reference
pygments: true
perex: The most important goal for any project is to get some numbers out of it. Let’s do it, using Ruby.
---

Analytics is all about numbers. Let's crunch some!

Multi-Dimensional Analytic Query Language (MAQL) is a proprietary querying language for creating project data models and retrieving project data through them. Fairly similar to SQL, MAQL is designed to optimize retrieval of data from your projects. In MAQL, you are **never** forced to talk about columns or to specify joins explicitly. This is a great aspect of the platform. However, there are some drawbacks. 

Same as SQL, MAQL is intended to be more user-friendly than system-friendly, which inhibits automation. However, the following, which may be surprising to you, makes MAQL a bit more challenging for humans, too:

{% highlight ruby %}
    SELECT SUM(Amount)
{% endhighlight %}

The above is not a MAQL statement (even though you may seen it in the GoodData Portal). The more accurate statement, which corresponds to what is transferred over the network, is the following:

{% highlight ruby %}
    SELECT SUM([/gdc/md/132131231/obj/1])
{% endhighlight %}

This complexity is deliberately hidden from the end user in the GoodData Portal. For developers using APIs, the second command is reality. The URI reference to the object in the project corresponds to the metric Amount. 

Ruby SDK tries to alleviate the situation with some tricks and tools to **programmatically define and manage reports**. In fact, Ruby SDK lays the foundations for **test driven BI**.

###Jack in

Before you begin, you should create your first Ruby project. For best results, please use the following tutorial: [Your first project](http://sdk.gooddata.com/gooddata-ruby/recipe/your-first-project).

If you created the above Ruby project, please locate the directory where a Goodfile is located, containing project_pid values. 

You may use the gooddata jack_in command to log in to the platform and to spin up an interactive session inside your example project. If you do not have such a project or wish to explore on your own, you can override the behavior by explicitly specifying the project yourself, as in the following:

{% highlight sql %}
    gooddata -p project_id project jack_in
{% endhighlight %}

After you jack in, let's have a look around. From the tutorial project, there are no metrics:

{% highlight ruby %}
    GoodData::Metric[:all]
    > []
{% endhighlight %}

You should have one fact: 

{% highlight ruby %}
    GoodData::Fact[:all]
    > [{"link"=>"/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/223",
      "author"=>"/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248",
      "tags"=>"",
      "created"=>"2014-02-18 07:44:26",
      "deprecated"=>"0",
      "summary"=>"",
      "title"=>"Lines changed",
      "category"=>"fact",
      "updated"=>"2014-02-18 07:44:26",
      "contributor"=>"/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248"}]
{% endhighlight %}

###The First Metric

Let's create our first metric. Ruby SDK supports a couple of ways to create metrics. Regardless of your preferred method, the end-result is the same, so pick the one that suits your style or situation.

TBD(add identifier based metric)

{% highlight ruby %}
    m = GoodData::Metric.create("SELECT SUM([/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/223])")
{% endhighlight %}

Yes, you can create metrics like the above, ugly and verbose. You may also reference the name of the fact when creating the metric:

{% highlight ruby %}
    m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')
{% endhighlight %}

Let's check out some things. First, we are not using the create method any more. Method xcreate stands for **eXtended notation**, which attempts to render the create expression into valid MAQL. Note also that when specifying the name of the fact, you use #"NAME" notation.

Either way, you've created a metric. Remember, this metric is only stored locally on your computer, since it has not been saved yet. So, let's save it!

{% highlight ruby %}
    m.save
    > RuntimeError: Metric needs to have title
{% endhighlight %}

Ah! Ok. We have two options for adding a title:

{% highlight ruby %}
    m.title = "My shiny metric"
{% endhighlight %}

or:

{% highlight ruby %}
    m = GoodData::Metric.xcreate(:title => "My shiny metric", :expression => 'SELECT SUM(#"Lines changed")')
{% endhighlight %}

Go ahead and try saving it again:

{% highlight ruby %}
    m.save
    > #<GoodData::Metric:0x007f95b609b548 ....
{% endhighlight %}

Great, looks good! The returned value indicates that the save has been successful. You can acquire some values from the saved object from the Platform:

{% highlight ruby %}
    m.saved?
    > true
{% endhighlight %}

{% highlight ruby %}
    m.uri
    > "/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/292"
{% endhighlight %}

Now, let's get some numbers using our new metric. Execute the metric:

{% highlight ruby %}
    m.execute
    > 9.0
{% endhighlight %}

Fantastic! You've just created your first report via API.

###Notes on Working with Metrics

Can you just execute stuff to poke around? Kind of.

The API does not allow you to execute a metric without it being saved first (for now). The Ruby SDK tries to hide this fact from you, but sometimes you can see the exposed wiring. 

Let's explore. Here is well-known metric:

{% highlight ruby %}
    m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')
{% endhighlight %}

Now try executing it:

{% highlight ruby %}
    m.execute
    > 9
{% endhighlight %}

It works. Behind the scenes, however, the Ruby SDK saves the metric and then deletes it again. It works, mostly:

{% highlight ruby %}
    m.is_saved?
    > false
{% endhighlight %}

{% highlight ruby %}
    m.uri
    > nil
{% endhighlight %}

Sometimes, you can see inconsistencies:

{% highlight ruby %}
    m.title
    > "Untitled metric"
{% endhighlight %}

Don't let this stop you with exploring. Just keep it in mind. Hopefully, it will go away soon.

###Defining a ReportDefinition

OK, we have our great metric. Now, it would be interesting to see a report on it, right? 

Let's create a report with the metric broken down by something. If you are familiar with the model, you know the metric is a summation of lines changed in all commits in all products made by all developers. 

Let's see how developers have contributed:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(:top => ["attr.devs.id"], :left => [m])
    > [ 1  |  2  |  3 ]
      [1.0 | 3.0 | 5.0]
{% endhighlight %}

Again, there are many ways to achieve the same result, so let's see what is available right now. 

####Referencing attributes

You can already see that you have a metric by reference, and an attribute can be referenced just by a string **containing an identifier**. 

Let's pass the attribute as an object, too:

{% highlight ruby %}
    a = GoodData::Attribute.get_by_id("attr.devs.id")
    GoodData::ReportDefinition.execute(:top => [a], :left => [m])
{% endhighlight %}

In the GoodData UI, a report is defined by using **Display Forms (or labels)**; the specific attributes are not used. If you specify an attribute, the Ruby SDK takes the first label of the attribute by default. In most cases, attributes have just one label, and this method works fine. 

In other instances, attributes have multiple labels, so you must be more specific. Coincidently, our attribute has two labels:

{% highlight ruby %}
    a.display_forms.count
    > 2
{% endhighlight %}

The identifiers are "label.devs.email" and "label.devs.id". Let's try using those labels in our report definition:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(:top => ["label.devs.id"], :left => [m])
    GoodData::ReportDefinition.execute(:top => ["label.devs.email"], :left => [m])
{% endhighlight %}

You can even do something, which you cannot do in the UI: use both labels at the same time (sic):

{% highlight ruby %}
    GoodData::ReportDefinition.execute(:top => ["label.devs.id", "label.devs.email"], :left => [m])
{% endhighlight %}

In these examples, you typically have only one item in the top or left section. To save some typing, you can omit the array literal, since there's only item to add. The Ruby SDK wraps them for you:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(:top => "label.devs.id", :left => m)
{% endhighlight %}

You may also refer to the object by title:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(
     :top => [{:type => :attribute, :title => "Month/Year (committed_on)"}],
     :left => m)
{% endhighlight %}

####Referencing by RegEx

Underneath, Ruby SDK uses `MdObject.find_first_by_title`, so you may also enter a RegExp literal:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(
     :top => [{:type => :attribute, :title => /Month\/Year/}],
     :left => m)
{% endhighlight%}

{% highlight ruby %}
    GoodData::ReportDefinition.execute(
     :top => [{:type => :attribute, :title => /month\/year/i}],
     :left => m)
{% endhighlight%}

####Ambiguous references

You may have noticed that two attributes in our model have the same name: `Id`. However, title values do not have to be unique, so this is ok. 

For now, Ruby SDK selected the first one. In the future, a "this is ambiguous" error is likely to be thrown, much like a SQL client:

{% highlight ruby %}
    GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => m)
{% endhighlight %}

####Summary

All of the above information is combined in the following: 

{% highlight ruby %}
    a = GoodData::Attribute.find_first_by_title(/month\/year/i)
    GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => [m, a])
{% endhighlight %}

###Reports

Until now, you've been computing reports for demo purposes. It is easy to create a report that you would actually save and deploy into a project. Simple:

{% highlight ruby %}
    report = GoodData::Report.create(
      :title => "Fantastic report",
      :top => [{:type => :attribute, :title => /Month\/Year/}],
      :left => m)
    
    report.save
{% endhighlight %}

Note that we are using Report instead of ReportDefinition. All other values are the same. When you try to save the report, a title must be set. 

###Results

You now know how to create a report. Let's see what we can do with the results. 

The basics of this tutorial have shown you how to create metrics and reports programmatically and then save them for use in the GoodData Portal. However, other frameworks and tools can do this, too. 

The real power of the Ruby SDK is to enable developers to consume the objects that they create. Through the same framework, you can create project objects and then use them programmatically for other purposes, enabling you to **use GD as a basis for your application**. To extend it even further, in the following section you can use Ruby SDK as a foundation for **Test Driven BI development**.

Let's execute one of the previously defined reports, and this time let's store the result:

{% highlight ruby %}
    result = GoodData::ReportDefinition.execute(
      :top => [{:type => :attribute, :title => /month\/year/i}],
      :left => m)
    >
    [Jan 2014 | Feb 2014]
    [1.0      | 8.0     ]
{% endhighlight %}

The defined class is `ReportDataResult`. As you will see, it tries to conform to API of an array in key aspects:

{% highlight ruby %}
    result.class
    > GoodData::ReportDataResult
    
    result[0][0]
    > "Jan 2014"
    
    result[1][0]
    > 1.0
{% endhighlight %}

All numbers in the results are of `BigDecimal` class, so you should be able to perform additional computations without losing precision:

{% highlight ruby %}
    result[1][0].class
    > BigDecimal
{% endhighlight %}
    
Let's look at some methods that are useful for validating the results of your reports:

{% highlight ruby %}
    result.include_row? [1, 8]
    > true
    
    result.include_column? ["Feb 2014", 8]
    > true
{% endhighlight %}
    
The `result` object is coming from the GoodData Platform in a special format, but after some processing by the SDK, it is rendered as an 2D array. This rendering enables easy validation testing of a whole report:

{% highlight ruby %}
    result == [["Jan 2014", "Feb 2014"], [1, 8]]
{% endhighlight %}

Not enough? We have more for you!
