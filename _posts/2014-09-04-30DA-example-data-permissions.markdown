---
layout: guides
title:  "Data Permissions & User Filters"
date:   2014-07-09 10:00:00
categories: filter
tags:
- process
- schedule
pygments: true
perex: Create and manage Data Permissions or user privelages within a project or domain.
---


In this guide we are will use jack_in (ref: Automation Day 1) to look around a project's attributes and select a target object to assign data permissions on. Then, we will apply a regional "sales" permission to a fictional user "Paul". How many lines of code? 3. Let's get started!


- Open Terminal and jack_in to your project with this command.

{% highlight bash %}
gooddata -p PROJECT_ID -U YOUR-USERNAME -P YOUR-PASSWORD project jack_in
{% endhighlight %}

- For this next step we need to get the URI, using jack_in you won't need to dig through grey pages.  We are interested in adding the sales region so the we will use the 'attr.employees.department' attribute so type.

{% highlight ruby %}
GoodData::Attribute['attr.employees.department'].labels[0]
{% endhighlight %}

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/f6ba825c-3a62-4346-b670-9ff4551a4489.png">
<div>
<small>Copy the URI in the meta section of the label. </small></div>
</div>
</div>

- Copy the label and then download [this](https://s3.amazonaws.com/xnh/mandatory_user_filter.rb) script ([mandatory_user_filter.rb](https://s3.amazonaws.com/xnh/mandatory_user_filter.rb)).
- Open *mandatory_user_filter.rb* in your favorite text editor and change the login information and the PROJECT_ID to your information.
- Notice two important things, first the "login" column is the default where the user email (or username is located). Second, that you can assign different columns as the filter target so you could start with any user file and just point the filter to the right column.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/b3410a18-07d9-417b-89eb-b849ae6b95c1.png">
<div>
<small>Ruby SDK applies filter per-row based on the department column.</small></div>
</div>
</div>

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/5851b155-2f26-4818-bab5-fdc019625682.png">
<div>
<small>(demo.csv) The "login" column is for the user receiving the filter.</small></div>
</div>
</div>

- Keep in mind this normally would be thousands of rows long the code is exactly the same, each column of the CSV just needs to be defined and pointed to the right place. To apply your filter Open Terminal, (remember to cd Downloads), and run the follow command.

{% highlight ruby %}
ruby mandatory_user_filter.rb
{% endhighlight %}

- Check to make sure the filter worked by going to https://secure.gooddata.com/gdc/md/YOUR_PROJECT_ID/userfilters.

You are done!