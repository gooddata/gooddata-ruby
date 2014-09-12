---
layout: guides
title:  "Upload a Process to GoodData"
date:   2014-07-09 10:00:00
categories: process
tags:
- process
- schedule
pygments: true
perex: Uploaded zipped processes to be executed as jobs.
---

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/d417444a-e785-4059-bbea-cf8179b18091.png">
<div>
</div>
</div>
</div>

Jumping right in, let's deploy a process with three lines of code that will be executed on your computer. You will need two scripts to start: 

- Download, [demo](https://s3.amazonaws.com/xnh/process.zip) process ([process.zip](https://s3.amazonaws.com/xnh/process.zip)).
- Download [demo](https://s3.amazonaws.com/xnh/upload_process.rb) script to upload process to GoodData ([upload_process.rb](https://s3.amazonaws.com/xnh/upload_process.rb)).
- Open the file *upload_process.rb* which uploads the process to GoodData. You will need to enter the Project ID and change the email/password to your own.

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/a157686a-9f9a-451c-b3cc-2de71a4fcce9.png">
<div>
<small>The Ruby SDK targets the demo process you downloaded. </small></div>
</div>
</div>

It is important to see the what the script is doing here. First, it performs the traditional behavior by logging you in with "GoodData.connect" once that is complete, notice how it references the "process.zip" file. All of the Ruby processes must be uploaded as a Zip.

<div style="padding-top: 40px; padding-bottom: 40px;">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/214c84d8-6633-4e74-9261-3a2ab9c28b80.png">
<div>
</div>
</div>

Additionally, note the ':type => "RUBY"' option which is also passed to the deploy method. This option by default is GRAPH which is how a normal process is run on the GoodData platform.

- Execute the script. From Terminal, run:

{% highlight bash %}
ruby upload_process.rb
{% endhighlight %}

- Finally, check that your new Ruby process was created by visiting the [data integration console](https://secure.gooddata.com/admin/disc/#/overview/ALL/OK).

You are all done!
