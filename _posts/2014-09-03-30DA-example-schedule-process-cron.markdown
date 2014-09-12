---
layout: guides
title:  "Schedule Processes (Cron Jobs)"
date:   2014-07-09 10:00:00
categories: process
tags:
- process
- schedule
pygments: true
perex: Use Ruby to schedule and deploy active processes/jobs on the GoodData platform.
---


Today we will learn how to schedule a process to happen this weekend. Our platform (and not joking here) has a power-house tool that allows you to run Ruby scripts when you want on your project. Using the SDK you can easily schedule a process to happen with one line of code.


Sunday we are going to have your project email you automatically. How cool is that? Remember you can set up any process to do many things like synchronize users, import data streams, update models etc.

- First download this Ruby [script](https://s3.amazonaws.com/xnh/schedule_email.rb) which we will tell your project to run.
- Open the script and change the text in "CHANGE_TO_YOUR_EMAIL@gooddata.com" to your Gooddata email.
- Right click on your script in Mac Finder and select "Compress..." which will create a zip of the script. This is required to upload the process to GoodData. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/d40c73dc-b58f-4a3d-b63b-3aff98f66275.png">
<div>
<small>The Data Integration Service Console (Where processes live).</small></div>
</div>
</div>

- Now we are going to deploy the edited Ruby Script (schedule_email.rb) inside of a project. Go to this [link](https://secure.gooddata.com/admin/disc/#/projects) and select a test project. 
- After choosing a project click the "Deploy Process" button. I like to use "My First Project". 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/b8fcf293-f496-4a94-92df-a361c761e5a1.png">
<div>
<small>Be sure to select Ruby scripts.</small></div>
</div>
</div>

- Click on the package box and up the .zip of your Ruby script. Name the process whatever you would like. Make sure you change "Process Type" to "Ruby scripts". Then, click "Deploy".

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/3e3b727b-3177-41f5-ba61-dfbeb84a572a.png">
<div>
<small>Copy the Process ID.</small></div>
</div>
</div>

- You should see your new process. Go ahead and click on "Meta Data" You will need your Process ID AND your Project ID for the next script.

- Go back to your Terminal and we will use the SDK to quickly Schedule this process for this weekend. Start by downloading with [this template script](https://s3.amazonaws.com/xnh/schedule_process.rb). 

- Open the script and paste your user information, then add the Project ID and Process Id you copied from above. 

- Back in Terminal , make sure you run "cd Downloads" so that you are in the directory where you downloaded the "schedule_process.rb" script. 

<div style="padding-top: 40px; padding-bottom: 40px;">
<div class="center">
<img class="tutorial" src="https://gallery.mailchimp.com/cc49eba2c07a5a3f516bf3fed/images/9de0b217-7a44-419e-a270-44057dd8b0b6.png">
<div>
<small>Execute the script to schedule process.</small></div>
</div>
</div>

And you are done, the process is now scheduled. You can check by going back to the Data Integration Console.
