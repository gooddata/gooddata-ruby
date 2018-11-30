# GoodData API Ruby wrapper and CLI

A convenient Ruby wrapper around the GoodData RESTful API. The gem comes in two flavors.
It has a CLI client and it is a library which you can integrate into your application.

The best documentation for the GoodData API can be found using these resources:

 * https://sdk.gooddata.com/gooddata-ruby-doc
 * http://developer.gooddata.com/api
 * https://secure.gooddata.com/gdc
 * http://rubydoc.info/gems/gooddata/frames

## Status

[![Gem Version](https://badge.fury.io/rb/gooddata.png)](http://badge.fury.io/rb/gooddata)
[![Downloads](http://img.shields.io/gem/dt/gooddata.svg)](http://rubygems.org/gems/gooddata)
[![Dependency Status](https://gemnasium.com/gooddata/gooddata-ruby.png)](https://gemnasium.com/gooddata/gooddata-ruby)
[![Code Climate](https://codeclimate.com/github/gooddata/gooddata-ruby.png)](https://codeclimate.com/github/gooddata/gooddata-ruby)
[![Build Status](https://travis-ci.org/gooddata/gooddata-ruby.png)](https://travis-ci.org/gooddata/gooddata-ruby)
[![Coverage Status](https://coveralls.io/repos/gooddata/gooddata-ruby/badge.png)](https://coveralls.io/r/gooddata/gooddata-ruby)

## Install

If you are using bundler, add

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
* run `rake test` and make sure all tests pass
* run `rake cop` and make sure you did not introduce any new coding rules issues
* Send us a pull request. Bonus points for topic branches.

## Contributing

See our [contribution guidelines](/CONTRIBUTING.md).

## Credits

**Originally started by**

Pavel Kolesnikov [ <mailto:pavel@gooddata.com> / [@koles](http://twitter.com/koles) ]

**Actively developed and maintained by**

- [Jan Zdráhal](https://github.com/panjan) [ <mailto:jan.zdrahal@gooddata.com> ]
- [Jakub Mahnert](https://github.com/kubamahnert) [ <mailto:jakub.mahnert@gooddata.com> ]
- [Petr Gaďorek](https://github.com/Hahihula) [ <mailto:petr.gadorek@gooddata.com> ]

**Contributors**

- [Tomas Korcak](https://github.com/korczis) [ <mailto:korczis@gmail.com> / [@korczis](http://twitter.com/korczis) ]
- [Tomas Svarovsky](https://github.com/fluke777) [ <mailto:svarovsky.tomas@gmail.com> / [@fluke777](http://twitter.com/fluke777) ]
- [Patrick McConlogue](https://github.com/thnkr/)
- [Petr Cvengros](https://github.com/cvengros)

For full contributor info see [contributors page](https://github.com/gooddata/gooddata-ruby/graphs/contributors).

**Special thanks to**

- Thomas Watson Steen [ <mailto:w@tson.dk> / [@wa7son](http://twitter.com/wa7son) ].

## Copyright

Copyright (c) 2010 - 2018 GoodData Corporation and Thomas Watson Steen. See [LICENSE](/LICENSE) for details.
