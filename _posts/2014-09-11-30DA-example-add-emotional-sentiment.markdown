---
layout: guides
title:  "Add Emotional Sentiment To Your Project"
date:   2014-07-09 10:00:00
categories: cool
tags:
- model
- project
pygments: true
perex: Adds three domains of sentiment to data and demonstrates how to integrate that into the a GoodData model.
---

Using the machine learning library *Sentimental* we will learn how to add sentiment to a users comments in our demo project. This is important for two reasons: A. How unbelieavably cool is it to be able to have your computer read hundreds of millions of comments and tell you how each "feels" but B. This snippet is meant to unlock your mind regarding what will now be possible with the Ruby SDK.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/c45b373f-f56e-449c-8b6a-b3fd95be78ef.png">
<div>
</div>
</div>
</div>

- First we need to add "comments" to our model. This is not problem, open Terminal and "cd my_test_project" or wherever it is that you scaffolded your project.

- Open *model.rb* and add the following code to the 'devs' block so that they can read the sentiment and comment.

{% highlight ruby %}
gd.add_label("comment", :reference => "dev_id")
gd.add_label("sentiment", :reference => "dev_id")
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/c2989ca2-75ab-4d20-9d5c-e44390bdebfb.png">
<div>
</div>
</div>
</div>

- Download demo data [dev_comments.csv](https://s3.amazonaws.com/xnh/devs_comments.csv) which includes the comments and the [sentiment.rb](https://s3.amazonaws.com/xnh/sentiment.rb) script, transfer both to the root directory of the "my_test_project."

- Re-open Terminal and make sure you are inside of the "my_test_project" directory and install the sentimental gem.

{% highlight bash %}
cd my_text_project && gem install sentimental
{% endhighlight %}

- Open *sentiment.rb* and change the PROJECT ID and the login credentials.

- Next open the new devs_comments.csv file which now has comments. Recall that the old devs data file included with scaffold is available inside the data/ folder. From inside Terminal type:

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/b826fece-1e15-4384-88a9-21cc33484878.png">
<div>
<small>dev_comments.csv with new comments column.</small></div>
</div>
</div>

- OK! Now go ahead and run in Terminal.

{% highlight bash %}
ruby sentiment.rb
{% endhighlight %}

- When the process is complete you can open the newly created devs_sentiment.csv. To see the emotional state of each comment.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/5cff6990-c0d7-4ef8-a4f4-dcef9a0b2cd5.png">
<div>
<small>Updated dev_comments.csv with new sentiment column.</small></div>
</div>
</div>

And that is it! You have brought emotions into the land of logic and made a brave forey into the world of machine learning.
