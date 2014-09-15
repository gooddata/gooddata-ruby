---
layout: guides
title:  "Create Data Models"
date:   2014-07-09 10:00:00
categories: cool
tags:
- model
- project
pygments: true
perex: A comprhensive one page script which replaces any GUI for building an entire project creating a model, uploading data, and inviting users.
---

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/fdee369d-30bb-4897-bf44-6bfdbdec0662.png">
<div>
</div>
</div>
</div>

Take a moment and think about the time it takes for you to set up a project in Cloud Connect, import the data, assign the token, load the data etc, etc. With this One Page Project example as an amazing proof-of-concept you will use the Automation SDK to build everything within one script.

*Steps*
1. New Project.
2. Sample data uploaded.
3. Model Setup.
4. Guest Users Invited.
5. Sample Metric Generated.
6. Demo Report.

- Start by download the One Page Project [here](https://s3.amazonaws.com/xnh/onepage.rb) ([onepage.rb](https://s3.amazonaws.com/xnh/onepage.rb)).

- The script starts off by logging you in and assembling a blueprint. Change the *LOGIN* information and the *AUTH_TOKEN* which you got from [here](https://developer.gooddata.com/trial/).

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/555a8b0f-8feb-47da-85d3-317b9ff69d4a.png">
<div>
<small>Facts, Dates, Anchors all added to the Model before uploading the project to GoodData.</small></div>
</div>
</div>

- Notice how the model is assembled programmatically within the blueprint.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/c3523365-e6df-463f-a99a-e87a55cfe467.png">
<div>
</div>
</div>
</div>

- Once the project is saved on line 27 the script jumps to uploading demo data to the project in context of the model of the blueprint we just created.

- Next, the script creates and saves a Metric and a Report to demo. Notice the type of the metric is not defined so it will default to SUM. You would assign the type within the create_metric method like this: "p.fact('fact.name').create_method(:type => :avg)"

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/601f45bd-ab95-429f-98de-b5167a5d92ea.png">
<div>
</div>
</div>
</div>

- And to top it all off, the project invites two users to join the project sending them a personalized method with the url of the newly created report.

- Alright, you ready? Go ahead and run the project script by opening Terminal and "cd Downloads" then:
Each blueprint is broken has these seven methods which tell Ruby how to build the model. Most of these are self-explanatory.

{% highlight bash %}
ruby onepage.rb
{% endhighlight %}

That's it!
