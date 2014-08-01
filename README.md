# GoodData API Ruby wrapper and CLI

A convenient Ruby wrapper around the GoodData RESTful API. The gem comes in two flavors.
It has a CLI client and it is a library which you can integrate into your application.

The best documentation for the GoodData API can be found using these resources:

 * http://sdk.gooddata.com/gooddata-ruby/
 * http://docs.gooddata.apiary.io/
 * http://developer.gooddata.com/api
 * https://secure.gooddata.com/gdc
 * http://rubydoc.info/gems/gooddata/frames

## Status

[![Gem Version](https://badge.fury.io/rb/gooddata.png)](http://badge.fury.io/rb/gooddata)
[![Dependency Status](https://gemnasium.com/gooddata/gooddata-ruby.png)](https://gemnasium.com/gooddata/gooddata-ruby)
[![Code Climate](https://codeclimate.com/github/gooddata/gooddata-ruby.png)](https://codeclimate.com/github/gooddata/gooddata-ruby)
[![Build Status](https://travis-ci.org/gooddata/gooddata-ruby.png)](https://travis-ci.org/gooddata/gooddata-ruby)
[![Coverage Status](https://coveralls.io/repos/gooddata/gooddata-ruby/badge.png)](https://coveralls.io/r/gooddata/gooddata-ruby)

## Install

If you are using bundler. Add

    gem "gooddata"

into Gemfile

and run

    bundle install

If you are using gems just

    gem install gooddata

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself we can ignore when we pull)
* run `rake test` and make sure all tests passes
* run `rake cop` and make sure you did not introduced any new coding rules issues 
* Send us a pull request. Bonus points for topic branches.

## Credits

This project is developed and maintained by Pavel Kolesnikov [ <mailto:pavel@gooddata.com> / [@koles](http://twitter.com/koles) ] and Tomas Svarovsky [<mailto:svarovsky.tomas@gmail.com> / [@fluke777](http://twitter.com/fluke777)]

Special thanks to Thomas Watson Steen [ <mailto:w@tson.dk> / [@wa7son](http://twitter.com/wa7son) ]

## Copyright

Copyright (c) 2010 - 2014 GoodData Corporation and Thomas Watson Steen. See LICENSE for details.

