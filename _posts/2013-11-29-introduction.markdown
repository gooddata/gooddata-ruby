---
layout: gs-template
title:  "Part I - Introduction"
date:   2014-01-19 13:56:00
categories: introduction
next_section: get-started/get-started-part-1-setting-up
pygments: true
perex: Getting started with Ruby and first steps with the GoodData Gem.
---
## Get Started
1. Setup GoodData Developer [account](https://secure.gooddata.com/account.html?#/registration/projectTemplate/urn%3Agooddata%3AOnboarding).
2. Set up your Ruby environment. Supported versions of Ruby are 1.9, 2.0 and higher. JRuby 1.7 (JRuby 1.8 is not supported).
3. If you are creating new projects or have Administrator access to any project that you wish to modify, you will need a [project token](https://developer.gooddata.com/trial/).

#### Install

If you are using Ruby Gems:

{% highlight ruby %}
gem install gooddata
{% endhighlight %}

If you are using bundler, add...

{% highlight ruby %}
gem "gooddata"
{% endhighlight %}

..into the Gemfile and run:

{% highlight ruby %}
bundle install
{% endhighlight %}

Thats it! Next, if you are new to Ruby and want to get the basics of using a Ruby Gem start with [Part I](http://sdk.gooddata.com/gooddata-ruby/get-started/get-started-part-1-setting-up). If not, skip straight ahead to [Part II](http://sdk.gooddata.com/gooddata-ruby/get-started/get-started-part-2-your-first-project) in the Tutorial.
