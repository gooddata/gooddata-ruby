---
layout: post
title:  "Crunching numbers"
date:   2014-01-19 13:56:00
categories: recipe
next_section: recipe/test-driven-development
prev_section: recipe/model
pygments: true
perex: Regardless of how much other things there are in the project the most important thing is to get some numbers out. Let's do it. With Ruby.
---

Analytics is all about numbers. Let's crunch it! The MAQL is a language that is fairly similar to SQL but it is aimed towards getting the data from the multidimensional system. You are **never** forced to talk about columns and specify joins explicitly. This is great, but again there are some drawbacks. Same as SQL, MAQL is aimed towards users more than machines which does not help for automation but there is one more caveat that make it hard to use even for humans. This will probably be a surprise to you

{% highlight ruby %}
SELECT SUM(Amount)
{% endhighlight %}

Is not a MAQL statement (even though you probably have seen this inside GoodData UI). The more correct (and what goes back and forth over the wire) is

{% highlight ruby %}
SELECT SUM([/gdc/md/132131231/obj/1])
{% endhighlight %}

GoodData UI does a great job hiding this complexity from you but this significantly complicate the use of MAQL over the API by "regular Joes". Ruby SDK tries to alleviate the situation with some tricks. It also gives you many tools to **programmatically define and deal with reports** and lays the foundations for **test driven BI**.

###Jack in

If you do not have a project best would be to create one by following our tutorial - [Your first project](http://sdk.gooddata.com/gooddata-ruby/recipe/your-first-project) so you can get predictable results.

If you have a project created according to that tutorial you should have a directory where a Goodfile with filled in projec_pid is. If you call gooddata jack_in it will try to log you in and spins up an interactive session inside that project. If you do not have a project like that or you want to explore on your own you can always override the behavior by explicitely specifying the project yourself like (obviously the mileage may vary)

{% highlight%}
gooddata -p project_id jack_in
{% endhighlight %}

So jack in your preferred way and let's look around. There are no metrics

{% highlight ruby %}
GoodData::Metric[:all]
  > []
{% endhighlight %}

there is one fact

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

Let's create our first metric. There are couple ways so I will show them one by one. Regardless of how you create the metric the result is the same so pick the one that suits your style or situation.

TBD(add identifier based metric)

{% highlight ruby %}
m = GoodData::Metric.create("SELECT SUM([/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/223])")
{% endhighlight %}

You can do it like this but obviously this is the ugly verbose way.

{% highlight ruby %}
m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')
{% endhighlight %}

Here you are using the name of the fact. Let's notice several things. First, we are not using create any more. Method xcreate stands for **eXtended notation** and tries to turn it into valid MAQL. When you are specifying the fact you are doing it by using #"NAME".

No matter which way you've used you have a metric definition. Remember, that metric is only locally on your computer we haven't saved it yet. So, let's do it!

{% highlight ruby %}
m.save
   > RuntimeError: Meric needs to have title
{% endhighlight %}

Uh ok! My bad. You have two options of adding title

{% highlight ruby %}
m.title = "My shiny metric"
{% endhighlight %}

or

{% highlight ruby %}
m = GoodData::Metric.xcreate(:title => "My shiny metric", :expression => 'SELECT SUM(#"Lines changed")')
{% endhighlight %}

Go ahead and try saving it, again.

{% highlight ruby %}
m.save
  > #<GoodData::Metric:0x007f95b609b548 ....
{% endhighlight %}

Great, looks good! Let's see if it has been succesfull 

{% highlight ruby %}
m.saved?
  > true
{% endhighlight %}

{% highlight ruby %}
m.uri
  > "/gdc/md/ptbedvc1841r4obgptywd2mzhbwjsfyr/obj/292"
{% endhighlight %}

Let's get some numbers. You can execute the metric.

{% highlight ruby %}
m.execute
   > 9.0
{% endhighlight %}

Fantastic! You've just created your first report via API.

###More on Metric Execution

Maybe you are wondering if you cannot just execute stuff to poke around. Well, you kinda can. The API does not allow you to execute a metric without it's being saved (but we hope this will change soon). SDK tries to hide this from you but sometimes you can see the wiring. Let's explore. This is our well known metric

{% highlight ruby %}
m = GoodData::Metric.xcreate('SELECT SUM(#"Lines changed")')
{% endhighlight %}

Let's try executing it

{% highlight ruby %}
m.execute
  > 9
{% endhighlight %}

It works. What happens behind the scenes is that SDK saves the metric and then deletes it again. It should mostly work

{% highlight ruby %}
m.is_saved?
  > false
{% endhighlight %}

{% highlight ruby %}
m.uri
  > nil
{% endhighlight %}

But sometimes you can see some inconsistencies.

{% highlight ruby %}
    m.title
    > "Untitled metric"
{% endhighlight %}

This should not stop you most of the time. Just keep this in your mind. Hopefully, it will go completely away soon.

###Defining a ReportDefinition

OK. We have our great metric. Now, it would be interesting to see a report, right? The metric broken down by something. If you are familiar with the model you know the metric is a summation of lines changed in all commits in all products made by all developers. Let's see, how developers has contributed.

{% highlight ruby %}
GoodData::ReportDefinition.execute(:top => ["attr.devs.id"], :left => [m])
  > [ 1  |  2  |  3 ]
    [1.0 | 3.0 | 5.0]
{% endhighlight %}

Again, there are a lot of ways how to achieve the same result so let's have a look at what is available right now. You can already see that you have a metric by reference and attribute can be referenced just by a string **containing an identifier**. Let's pass the attribute as an object as well.

{% highlight ruby %}
a = GoodData::Attribute.get_by_id("attr.devs.id")
GoodData::ReportDefinition.execute(:top => [a], :left => [m])
{% endhighlight %}

If you studied GoodData UI well you know that Report is defined using **Display Forms (or labels)** not by attribute. If you are specifying an attribute, the SDK will take the first one automatically. This works well most of the time since attributes have typically just one label. Anyway, sometimes they have many so you need to be more specific. Coincidently our attribute has 2 labels.

{% highlight ruby %}
a.display_forms.count
  > 2
{% endhighlight %}

The identifiers are "label.devs.email" and "label.devs.id". Let's try using those

{% highlight ruby %}
GoodData::ReportDefinition.execute(:top => ["label.devs.id"], :left => [m])
GoodData::ReportDefinition.execute(:top => ["label.devs.email"], :left => [m])
{% endhighlight %}

You can even do something that you cannot do in the UI that is using both of the labels at the same time (sic).

{% highlight ruby %}
GoodData::ReportDefinition.execute(:top => ["label.devs.id", "label.devs.email"], :left => [m])
{% endhighlight %}

In almost all above cases we had only one thing in left or top section. You can save your fingers and not use the array literal if there is only one item in the section. SDK will wrap them for you.

{% highlight ruby %}
GoodData::ReportDefinition.execute(:top => "label.devs.id", :left => m)
{% endhighlight %}

Sometimes it might be useful to refer to the objects in a different way. You can do it by title

{% highlight ruby %}
GoodData::ReportDefinition.execute(
   :top => [{:type => :attribute, :title => "Month/Year (committed_on)"}],
   :left => m)
{% endhighlight %}

Since underneath it uses `MdObject.find_first_by_title` it also accepts RegExp literal

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

In our model we have two attributes with the same name - `Id`. Since the title does not have to be unique this is ok. Currently, it will pick the first for you but this behavior will most likely change in the favor of throwing a "this is ambiguous" error, much like your SQL client probably does.

{% highlight ruby %}
GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => m)
{% endhighlight %}

Of course you can combine all things we learned together.

{% highlight ruby %}
a = GoodData::Attribute.find_first_by_title(/month\/year/i)
GoodData::ReportDefinition.execute(:top => [{:type => :attribute, :title => "Id"}], :left => [m, a])
{% endhighlight %}

###Reports

Up until now we have been computing the reports just because. Maybe you wonder how you can actually create a report that would be saved. Simple.

{% highlight ruby %}
report = GoodData::Report.create(
   :title => "Fantastic report",
   :top => [{:type => :attribute, :title => /Month\/Year/}],
   :left => m)
    
report.save
{% endhighlight %}

Note that we are using Report instead of ReportDefinition. Everything else being the same. Also report needs a title set at the time you would try saving it.

###Results

Well, we already know how to create a report. Now, let's see what we can do with the result. The point of this framework is not only you being able to create reports programmatically and save them for consumption over the UI. For sure this is incredibly useful, but when we have that why stop there. With Ruby SDK you can actually consume the result programmatically as well so you can **use GD as a basis for your application**. Or as I will show you in the following section we build a foundation for **Test Driven BI development**.

Let's execute one of the previously defined reports and this time let's store the result

{% highlight ruby %}
result = GoodData::ReportDefinition.execute(
    :top => [{:type => :attribute, :title => /month\/year/i}],
    :left => m)
   >
   [Jan 2014 | Feb 2014]
   [1.0      | 8.0     ]
{% endhighlight %}

The class is `ReportDataResult`. As you will see further it tries to conform to API of an array in key aspects

{% highlight ruby %}
result.class
  > GoodData::ReportDataResult
    
result[0][0]
  > "Jan 2014"
    
result[1][0]
  > 1.0
{% endhighlight %}

All the numbers are of `BigDecimal` class so you should be able to perform additional computations without losing precision

{% highlight ruby %}
result[1][0].class
  > BigDecimal
{% endhighlight %}
    
Let's look on some methods that are useful for validating the results of reports

{% highlight ruby %}
result.include_row? [1, 8]
  > true
    
result.include_column? ["Feb 2014", 8]
  > true
{% endhighlight %}
    
Result is coming from server in a special format but after some processing it is just an 2D array so it's no wonder that you can test on equality of a whole report.

{% highlight ruby %}
result == [["Jan 2014", "Feb 2014"], [1, 8]]
{% endhighlight %}

Not enought? We have more for you!
