---
layout: reference
title:  "Working with a project"
date:   2014-01-19 13:56:00
categories: reference
pygments: true
perex: "Learn how to work with a project: clone it, copy reports, and do various other tasks."
---

In the GoodData platform, the basic building block is a project, which corresponds to a datamart. In this section, we go over several useful project-related tasks and how to execute them using the Ruby SDK.

##CLI

Before we dig into the APIs, let's briefly explore the capabilities of the command line interface for project manipulation.

###Create a project

TBD

###Clone project
Cloning a project is easy and very useful for testing and making backups:

{% highlight ruby %}
  gooddata -p PROJECT_ID project clone --data --users --name "Name of the new project"
{% endhighlight %}

This command creates an exact clone of your project. The following parameters can be applied:

--data/--no-data does or does not clone the data in the source project into the clone.
--users/--no-users does or does not clone the users in the source project into the clone. The user who creates the clone is always added as the owner and project Administrator of the clone. 

By default, a project is cloned with data and without all users.

###Delete project

**WARNING: Deleting a project cannot be reverted.**

{% highlight ruby %}
  gooddata -p PROJECT_ID  project delete
{% endhighlight %}

###Show info 

Use the following to review basic information about a project:

{% highlight ruby %}
  gooddata -p PROJECT_ID  project show
{% endhighlight %}

###Validation

The following command executes a project validation, including any detected problems with referential integrity. 

**Tip:** From time to time, you should run this command to keep your project clean.

{% highlight ruby %}
  gooddata -p PROJECT_ID  project validate
{% endhighlight %}

###List users

List all users in a specified project:

{% highlight ruby %}
  gooddata -p PROJECT_ID  project users
{% endhighlight %}

###List roles

List all roles in a specified project:

**NOTE:** Project roles are specific to a project. Users cannot be added to a project without a project role.

{% highlight ruby %}
  gooddata -p PROJECT_ID  project roles
{% endhighlight %}

##API

Using the GoodData APIs, you can begin exploring the capabilities of the Ruby SDK:

###Creating a project

{% highlight ruby %}
GoodData::Project.create(
  :title => title,
  :summary => summary,
  :template => template,
  :auth_token => token
)
{% endhighlight %}

* For API documentation, see [Project API](https://developer.gooddata.com/api#project).

###Defining a working project

Most of your platform operations occur inside a project. As part of your basic workflow, you must select a specific project. All of the following are equivalent methods for selecting a project:

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

The project remains the selected one until you change it. 

If you are working with several projects at the same, you can specify individual commands to apply to a specific project, in case the active project has been specified somewhere further upstream. Use the `with_project` method:

{% highlight ruby %}
  GoodData.with_project(project_id) do
    processes = GoodData::Process.all
  end
{% endhighlight %}

The `project_id` value can be specified as either a string or a project identifier. 
* The `project_id` value is applied only within the code block. When the block completes execution, the active project is reverted to the value that was set before the code block execution. 
* You must provide a code block with one parameter, which must be the GoodData::Project object. 

###Cloning a project

You can clone a project through the APIs. The parameters and their defaults are the same as those specified for the command-line interface version, enabling you to choose to optionally include data and users from the source project into the clone. 

* For API documentation, see [Project API](https://developer.gooddata.com/api#project).

{% highlight ruby %}
project = GoodData::Project['project_id']
project.clone(
  :title => "Title of the cloned project",
  :with_data => true,
  :with_users => true
)
{% endhighlight %}

###Deleting a project

**WARNING: Deleting a project cannot be reverted.**

{% highlight ruby %}
project = GoodData::Project['project_id']
project.delete
{% endhighlight %}

###Validating a project

Use the following to validate a project, which also checks for referential integrity issues:

{% highlight ruby %}
project = GoodData::Project['project_id']
project.validate
{% endhighlight %}
* For API documentation, see [Data Model API](https://developer.gooddata.com/api#data-model).

###Transfer objects between projects

Suppose you have two projects. In one, you have created a new report, and you would like to transfer this object to the other project. 

The `transfer_objects` can be used to transfer metrics, dashboards and reports. 

**NOTE:** Before you transfer objects, please verify that the logical data models of the projects are identical or are unlikely to cause conflicts with the imported objects.

{% highlight ruby %}
project_from = GoodData::Project['project_id_from_which_migrate']
project_to = GoodData::Project['project_id_to_which_migrate']
objects = GoodData::Report.all.first
project_from.object_transfer(objects, :project => project_to)
{% endhighlight %}

You can use one of multiple supported methods for specifying projects and objects: Project id or project object for projects and object_id, uri and the object itself for the objects.

* For API documentation, see [Metadata API](https://developer.gooddata.com/api#metadata).

###Inviting a user
{% highlight ruby %}
project = GoodData::Project['project_id']
project.invite('john@example.com', :admin, "Welcome John, enjoy this project")
{% endhighlight %}

You can invite more than one user
{% highlight ruby %}
project.invite(['john@example.com', 'jane@example.com'], "admin", "Welcome, enjoy this project")
{% endhighlight %}

To know what roles you have in a project. You can call

{% highlight ruby %}
project.roles
{% endhighlight %}

on the project.

{% highlight ruby %}
project.roles.map(&:title)
{% endhighlight %}

Will print the titles of the roles which you can use for the invite command.

###Project management
You can use the following commands to manage basic aspects of your project:

{% highlight ruby %}
project = GoodData::Project['project_id']
project.title
project.uri
project.title = "Let's rename it"
project.save
{% endhighlight %}
