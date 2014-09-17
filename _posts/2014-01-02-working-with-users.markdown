---
layout: guides
title:  "Working With Users & Invitations"
date:   2014-01-19 13:56:00
categories: general
pygments: true
perex: Invite users from and into project.
---

Users are integral part of any project. Who else would look at your beautiful data. Let's investigate ways how users can be invited so they can participate in the project.

###Working with project users

####Listing
You can get users in particular project like this

{% highlight ruby %}
client = GoodData.connect 'YOUR_USER@gooddata.com', 'YOUR_PASSWORD'
project = GoodData::Project['YOUR-PROJECT-ID', :project => project]
project.users
{% endhighlight %}

These are not really user objects but they are very similar. So thanks to duck typing you can treat them very similarly.

{% highlight ruby %}
project_user = project.users.first
project_user.first_name
{% endhighlight %}

####Getting roles in project

You can also look at what roles are available in particular project

{% highlight ruby %}
project.roles
{% endhighlight %}

on the project. This

{% highlight ruby %}
project.roles.map(&:title)
{% endhighlight %}

####Setting roles
You can set user a specific role.

{% highlight ruby %}
project_user.role
project_user.role = admin_role
{% endhighlight %}


####Enablind/disabling

`Coming in 6.2`

There is not a way how you can remove the user form the project completely but you can disable and enable them. 
You can also disable them

{% highlight ruby %}
project_user.disable
{% endhighlight %}

and later enable if you wish

{% highlight ruby %}
project_user.enable
{% endhighlight %}

Thanks to power of ruby you can do mass purges of users. For example disablng all editors in 4 lines of code

{% highlight ruby %}

client = GoodData.connect 'YOUR-USER@gooddata.com', 'YOUR-PASS'
project = GoodData::Project['YOUR-PROJECT-ID', :client => client]

editor_role = project.roles.find { |role| role.title == "Editor" }
project.users.select do |project_user|
  project_user.role == editor_role
end.each { |editor| editor.disable }

{% endhighlight %}

##Adding users to the project
There are generally two ways how to add user to a project. Let's look at the first one

###Inviting user to project

Inviting is a process that requires cooperation of the invitee. If you invite him he is sent an email. If he accepts he is added to the project or taken through the registration process if he is not yet a user. User is in complete controll of his account you only controll whether he is or is not enabled in the project.

{% highlight ruby %}
invitation = project.invite('theemail@example.com', 'Editor', 'A welcome message for the Project!')
{% endhighlight %}

###Adding a user

Sometimes you want complete control over the users. This is typical scenario with SSO providers where you do not want user to know he has to create and manage a user at gooddata. In this case user is not sent an email and there is no action required on his side. You are in complete control of not ony his presence in a project but also his account. You can change his name, phone number and even password. The condition is that this user is added to an Domain (also called organization). And we get to that part in a minute. If you have a user in a domain you can add him to the project like this.

{% highlight ruby %}
user = project.add_user('email@example.com', 'Editor')
{% endhighlight %}

This will only work if you are an administrator of a domain, which the user is in. Let's have a look how to add a user to a domain.

{% highlight ruby %}
domain = GoodData::Domain['my_domain_name']
domain.add_user('joe@example.com', 'jindrisska')
{% endhighlight %}

Of course there are couple of things to make the work with domains easier

{% highlight ruby %}
domain.users
{% endhighlight %}

Both of these can be called statically

{% highlight ruby %}
GoodData::Domain.add_user('joe@example.com', 'jindrisska')
GoodData::Domain.users
{% endhighlight %}