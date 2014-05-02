---
layout: reference
title:  "Working with users and invitations"
date:   2014-01-19 13:56:00
categories: reference
pygments: true
perex: "Invite users from and into project."
---

##Wor

You can get users in particular project like this

{% highlight ruby %}
project.users
{% endhighlight %}

These are not really user objects but they are very similar. So thanks to duc typing you can treet them very similarly.

{% highlight ruby %}
project_user = project.users.first
project_user.first_name
{% endhighlight %}

###Getting roles in project

You can also look at what roles are available in particular project

{% highlight ruby %}
project.roles
{% endhighlight %}

on the project. This

{% highlight ruby %}
project.roles.map(&:title)
{% endhighlight %}

###Enablind/disabling

You can also call project specific methods
{% highlight ruby %}
project_user.role
project_user.role = admin_role
{% endhighlight %}

You can also disable them

{% highlight ruby %}
project_user.disable
{% endhighlight %}

and later enable if you wish

{% highlight ruby %}
project_user.disable
{% endhighlight %}

Thanks to power of ruby you can do mass purges of users. For example disablng all editors in 4 lines of code

{% highlight ruby %}
GoodData.with_project(pid) do |p|
  editor_role = p.roles.find {|role| role.title == "Editor"}
  p.users.select { |project_user| project_user.role == editor_role}.each { |editor| editor.disable }
end
{% endhighlight %}

##Adding users to the project
There are generally two ways how to add user to a project. Let's look at the first one

###Inviting user to project

Inviting is a process that requires cooperation of the invitee. If you invite him he is sent an email. If he accepts he is added to the project or taken through the registration process if he is not yet a user. User is in complete controll of his account you only controll whether he is or is not enabled in the project.

{% highlight ruby %}
GoodData.with_project("pid") do |p|
  invitation = p.invite(email, role, msg)
end
{% endhighlight %}

###Adding a user

Sometimes you want complete control over the users. This is typical scenario with SSO providers where you do not want user to know he has to create and manage a user at gooddata. In this case user is not sent an email and there is no action required on his side. You are in complete control of not ony his presence in a project but also his account. You can change his name, phone number and even password. The condition is that this user is added to an Domain (also called organization). And we get to that part in a minute. If you have a user in a domain you can add him to the project like this.

{% highlight ruby %}
GoodData.with_project("pid") do |p|
  p.add_user(email, role)
end
{% endhighlight %}

This will only work if you are an administrator of a domain, which the user is in. Let's have a look how to add a user to a domain.

{% highlight ruby %}
GoodData::Domain['my_domain_name']
{% endhighlight %}