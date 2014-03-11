# GoodData Ruby wrapper and CLI

A convenient Ruby wrapper around the GoodData RESTful API. The gem comes in two flavors.
It has a CLI client and it is a library which you can integrate into your application.

The best documentation for the GoodData API can be found using these resources:

 * http://docs.gooddata.apiary.io/
 * http://developer.gooddata.com/api
 * https://secure.gooddata.com/gdc

## Status

[![Gem Version](https://badge.fury.io/rb/gooddata.png)](http://badge.fury.io/rb/gooddata)
[![Dependency Status](https://gemnasium.com/gooddata/gooddata-ruby.png)](https://gemnasium.com/gooddata/gooddata-ruby)
[![Code Climate](https://codeclimate.com/github/gooddata/gooddata-ruby.png)](https://codeclimate.com/github/gooddata/gooddata-ruby)

## Install

If you are using bundler. Add 

    gem "gooddata"

into Gemfile 

and run 

    bundle install

If you are using gems just

    gem install gooddata

### Rake tasks

There are some out of box working tasks. Run `rake -T` to show them.

You should get output similar to this:

    rake build    # Build gooddata-0.6.0.pre9.gem into the pkg directory
    rake install  # Build and install gooddata-0.6.0.pre9.gem into system gems
    rake release  # Create tag v0.6.0.pre9 and build and push gooddata-0.6.0.pre9.gem to Rubygems
    rake spec     # Run RSpec code examples
    rake test     # Run tests
    rake yard     # Generate YARD Documentation

### Library usage


In its most simple form GoodData gem just cares about the logging in and juggling the tokens that are needed for you to retrive information. It provides you the usual HTTP methods that you are used to. Couple of examples.

#### Authentiacation

    GoodData.connect("login", "pass")

    # Different server than the usual secure.gooddata.com
    GoodData.connect("login", "pass", "https://different.server.gooddata.com")

    # the last argument is passed to underlying RestClient so you can specify other useful stuff there
    GoodData.connect("login", "pass", "https://different.server.gooddata.com", :timeout => 0)


#### Basic requests

    GoodData.get("/gdc/md")

    # This post will not actually work it is just for the illustration
    GoodData.post("/gdc/md/#{project_id}", {:my_object => "some_date"})

    # The same goes for put delete.
    # By default the response is decoded for you as json but sometimes you do not want that png or other stuff.
    # You will get the response object and you can query it further.
    response = GoodData.get("/gdc/md", :process => false)
    response.code == 400
    pp response.body

#### Loading of data

This library is able to load data but it is not used that much if at all. Since there is some data processing needed on the client side we rely on faster implementations in Java usually. Let us know if you would be interested. As the APIs improve we could bring it back.

#### Other stuff

The API is currently a little fragmented and we never had the guts to actually deal with all the ugliness and present nice object oriented API. Usually it is just better to deal with the ugly json as hashes. But there are couple of exceptions where we needed something better and we thought providing an abstraction is worth the hassle.

#### Working with obj

obj is a resource that is probably the oldest in all GoodData. Obj are all the objects that have something to do with the analytical engine (metrics, attributes, reports etc). You can find the docs here (Add link to apiary). There are coule of convenience methods to work with these

    GoodData.connect("svarovsky@gooddata.com", "just_testing")
    GoodData.project="fill_in_your_project_pid"

    # Access raw obj
    obj = GoodData::MdObject[obj_number]

    # bunch of useful methods are defined on these
    obj.title
    obj.get_used_by
    obj.get_using
    obj.delete


#### Working with reports

Sometimes it is useful to compute reports outside of UI so there are couple of convenience methods for that.

    require 'pp'

    GoodData.connect("svarovsky@gooddata.com", "just_testing")
    GoodData.project="fill_in_your_project_pid"

    report = GoodData::Report[1231]
    result = report.execute
    pp result

    File.open('png.png', 'w') do |f|
        f.write(report.export(:png))
    end

You can export even whole dashboards. Currently afaik reports can be exported either as xls and png and dashboards as pdf. Hopefully it will support more in the future.

    dash = GoodData::Dashboard[33807]
    File.open('dash.pdf', 'w') do |f|
        f.write(dash.export(:pdf))
    end

You can specify which tab to export. By default it is the first

    dash = GoodData::Dashboard[33807]
    File.open('dash.pdf', 'w') do |f|
        f.write(dash.export(:pdf, :tab => dash.tabs_ids.last))
    end

### CLI Usage

After installing the gooddata gem, GoodData is available from your command line using
the `gooddata` command. To get a complete overview of possible options type:

    gooddata help

The examples and descriptions below does not cover all the options available via the CLI.
So remember to refer back to the `help` command.

Before you do anything else, a good idea is to see if your account is set up correctly and 
that you can log in. To do this, use the `api:test` command:

    gooddata api:test

#### Authentication

As you saw if you ran the above test command <tt>gooddata</tt> will prompt you
for your GoodData username and password. If you don't wish to write your
credentials each time you connect to GoodData using <tt>gooddata</tt>, you can
create a simple gooddata credentials file called <tt>.gooddata</tt> in the root
of your home directory. To make it easy you can just run the credentials file
generator command which will create the file for you:

    gooddata auth:store

#### List available projects

To get a list of projects available to your GoodData user account, run:

    gooddata projects

The output from the above command will look similar to this:

```
   521  Some project
  3521  Some other project
  3642  Some third project
```

The first column contains the project-key. You need this if you wan't to either
see more details about the project using the `projects:show` comamnd or
if you wish to delete the project using the `projects:delete` command.

#### Create a new project

To create a new project under on the GoodData servers, run:

    gooddata projects:create

You will then be asked about the desired project name and summary before it's created.

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself we can ignore when we pull)
* Send us a pull request. Bonus points for topic branches.

## Credits

This project is developed and maintained by Pavel Kolesnikov [ <mailto:pavel@gooddata.com> / [@koles](http://twitter.com/koles) ] and Tomas Svarovsky <mailto:svarovsky.tomas@gmail.com>

Special thanks to Thomas Watson Steen [ <mailto:w@tson.dk> / [@wa7son](http://twitter.com/wa7son) ]

## Copyright

Copyright (c) 2010 - 2014 GoodData Corporation and Thomas Watson Steen. See LICENSE for details.
