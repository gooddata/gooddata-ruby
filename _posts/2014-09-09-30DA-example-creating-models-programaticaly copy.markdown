---
layout: guides
title:  "Create Data Models"
date:   2014-07-09 10:00:00
categories: model
tags:
- model
- blueprint
pygments: true
perex: Use the Automation SDK to design data models in Ruby code.
---

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/3164cd28-43e1-47f9-bd2b-f435182e33d3.png">
<div>
</div>
</div>
</div>

Today we will cover the basic components of a model which you will recognize at least in terminology with CloudConnect.

Each blueprint is broken has these seven methods which tell Ruby how to build the model. Most of these are self-explanatory.

*Functional*

- add_fact
- add_attribute
- add_date
- add_date_dimension

*Organizational*

- add_anchor
- add_dataset
- add_label

Get started by opening up the script inside of the demo project you created with "gooddata scaffold my_test_project". This script is located in *my_test_project/model/model.rb*. Remember the methods used above used to build the basic model in the demo project.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/417334d2-dbc2-4150-bdf5-e0f6baab88c2.png">
<div>
<small>model/model.rb</small></div>
</div>
</div>

- This next part is the most important part for you to understand. To help you, I have included a screenshot of what the same model looks like in CloudConnect. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/ccc168ef-13e2-4657-ac49-77b26d3c0640.png">
<div>
<small>The model referenced above desgined in Cloud Connect.</small></div>
</div>
</div>

- Notice that "add_anchor" is exactly the same as saying a connection point. 
- References are the programatic way of representing the actual arrow pointing to the dataset. 
- Labels is the label you know within GoodData so it is not represented but is available later in the report. 
- Go ahead and lets add in a fact in devs column which captures the number of lines of code a developer has written. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/1984b9dc-cba6-4f10-a476-77d69b466a16.png">
<div>
<small>Add a fact to the devs dataset.</small></div>
</div>
</div>

- Now all you must do is run the build command and you will have added a fact to the model in your project. First, open Terminal and make sure you "cd my_test_project" to make sure you are in the project directory and then jack_in (you will not need your project ID because it will be loaded from the Goodfile in your project directory).

{% highlight bash %}
gooddata -U YOUR_USERNAME -P YOUR_PASSOWRD project jack_in
{% endhighlight %}

- Update your project on the GoodData platform.

{% highlight bash %}
GoodData::Model::ProjectCreator.migrate(:spec => blueprint, :project=> 'PROJECT_ID')
{% endhighlight %}

That is it!

