---
layout: post
title:  "Working with a project"
date:   2014-01-19 13:56:00
categories: recipe
pygments: true
perex: Learn how to work with a project. Clone it copy reports and different things.
---

The basic building block is a project. There are several useful things that you can do with it. Let's see

##CLI

Before we delve into APIs let's briefly explore the capabilities of command line interface for project manipulation

###Create a project

TBD

###Clone project
You can easily clone project. This is very useful for testing and making backups of your project.

{% highlight ruby %}
  gooddata -p PROJECT_ID project clone --data --users --name "Name of the new project"
{% endhighlight %}

This will make an exact same clone of your project. There are three main parameters that you can use.

--data/--no-data will clone the project including data.
--users/--no-users will clone the project including all the users. If you opt out it will bring in just the user that is performing the cloning

The defaults are with data but without all users.

###Delete project

Be careful this cannot be reverted

{% highlight ruby %}
  gooddata -p PROJECT_ID  project delete
{% endhighlight %}

###Show info 

You can inspect a basic info about a project

{% highlight ruby %}
  gooddata -p PROJECT_ID  project show
{% endhighlight %}

###Validation

This will run a project validation. It would report for example referential integrity or other problems. It is a good practice to run this from time to time and keep it clean.

{% highlight ruby %}
  gooddata -p PROJECT_ID  project validate
{% endhighlight %}

###List users

You can list all the users in a project.

{% highlight ruby %}
  gooddata -p PROJECT_ID  project users
{% endhighlight %}

###List roles

You can list all the roles in a project.

{% highlight ruby %}
  gooddata -p PROJECT_ID  project roles
{% endhighlight %}

##API

Let's see at the capabilities of the SDK

###Creating a project

{% highlight ruby %}
GoodData::Project.create(:title => title, :summary => summary, :template => template, :auth_token => token)
{% endhighlight %}

###Setting up a working project

Majority of the operations that you want to perform is hapenning inside a project. So before you can work with it you have to select particular project. There are several ways to do it

These are all equivalent
{% highlight ruby %}
  GoodData.use(project_id)
{% endhighlight %}

{% highlight ruby %}
  GoodData.project = project_id
{% endhighlight %}

{% highlight ruby %}
  project = GoodData::Project["my_project_id"]
  GoodData.project = project
{% endhighlight %}

The project will stay set until you will change it. Sometimes you are working with several projects and you would like to be sure you are working on a specific project and not on some that might be set up somewhere up the stream. There is a useful method `with_project`.

{% highlight ruby %}
  GoodData.with_project(project_id) do
    processes = GoodData::Process.all
  end
{% endhighlight %}

You can provide either string or a project. You also have to provide a block with one parameter which will always be the GoodData::Project object. Nice thing about this method is that the project is only set up inside the project. Once the block finishes the project is set to the value that was set there previously.

###Cloning a project

You can clone a project. The meaning of the parameters and their defaults are the same as in the case of CLI.

{% highlight ruby %}
project = GoodData::Project['project_id']
project.clone(:title => "Title of the cloned project", :with_data => true, :with_users => true)
{% endhighlight %}

###Deleting a project
You can delete a project.

{% highlight ruby %}
project = GoodData::Project['project_id']
project.delete
{% endhighlight %}

###Validating a project
You can validate a project. This would report some problems like referential integrity issues etc.

{% highlight ruby %}
project = GoodData::Project['project_id']
project.validate
{% endhighlight %}

###Objects transfer
Imagine you have a project. You cloned it created some new report or dashboard and would like to transfer it back to the original project. This is what `transfer_objects` is for. You can transfer metrics, dashboards and reports. The models of the projects should ideally be identical.

{% highlight ruby %}
project_from = GoodData::Project['project_id_from_which_migrate']
project_to = GoodData::Project['project_id_to_which_migrate']
objects = GoodData::Report.all.first
project_from.object_transfer(objects, :project => project_to)
{% endhighlight %}

You can use any of the ways to specify both project or objects. Project id or project object for projects and object_id, uri and the object itself for the objects.

###Inviting a user
TBD

###Usual stuff
You can do the typical small stuf with a project

{% highlight ruby %}
project = GoodData::Project['project_id']
project.title
project.uri
project.title = "Let's rename it"
project.save
{% endhighlight %}
