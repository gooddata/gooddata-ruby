# GoodData API Ruby wrapper and CLI

A convenient Ruby wrapper around the GoodData RESTful API. The gem comes in two flavors.
It has a CLI client and it is a library which you can integrate into your application.

The best documentation for the GoodData API can be found using these resources:

 * https://sdk.gooddata.com/gooddata-ruby-doc
 * http://developer.gooddata.com/api
 * https://secure.gooddata.com/gdc
 * http://rubydoc.info/gems/gooddata/frames
 
Feel free to check out the [GoodData community website](http://community.gooddata.com/) if you have any questions about the GoodData Analytics platform, our API, or this library.

## Status

[![Gem Version](https://badge.fury.io/rb/gooddata.png)](http://badge.fury.io/rb/gooddata)
[![Downloads](http://img.shields.io/gem/dt/gooddata.svg)](http://rubygems.org/gems/gooddata)
[![Dependency Status](https://gemnasium.com/gooddata/gooddata-ruby.png)](https://gemnasium.com/gooddata/gooddata-ruby)
[![Code Climate](https://codeclimate.com/github/gooddata/gooddata-ruby.png)](https://codeclimate.com/github/gooddata/gooddata-ruby)
[![Build Status](https://github.com/gooddata/gooddata-ruby/actions/workflows/build.yml/badge.svg)](https://github.com/gooddata/gooddata-ruby/actions/workflows/build.yml/)

## Supported versions
 
In order to make the user experience with integrating GoodData Ruby SDK as smooth and secure as possible and to ensure that the SDK is using the latest features of the platform, we only provide support to the two most recent major versions of Ruby SDK. 
 
The most recent majors will be supported in the following modes:
 
- The latest major version will receive all new functionality and all bug fixes. 
- The previous major version will only receive fixes to critical issues and security fixes. These fixes will be applied on top of last released version of the previous major.
- GoodData customer support will provide support for the latest major and previous major version only.

- The customers are encouraged to always use the latest version of the Ruby SDK.
- In case of using older versions, the user might face API incompatibility, performance or security issues.
 
Please follow the installation instructions in the repository to update to the newest version.

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

Pavel Kolesnikov [ [@koles](http://twitter.com/koles) ]

**Actively developed and maintained by**

GoodData Team

**Contributors**

- [Jan Zdráhal](https://github.com/panjan) 
- [Jakub Mahnert](https://github.com/kubamahnert) 
- [Petr Gaďorek](https://github.com/Hahihula) 
- [Tomas Korcak](https://github.com/korczis) [ <mailto:korczis@gmail.com> / [@korczis](http://twitter.com/korczis) ]
- [Tomas Svarovsky](https://github.com/fluke777) [ <mailto:svarovsky.tomas@gmail.com> / [@fluke777](http://twitter.com/fluke777) ]
- [Patrick McConlogue](https://github.com/thnkr/)
- [Petr Cvengros](https://github.com/cvengros)

For full contributor info see [contributors page](https://github.com/gooddata/gooddata-ruby/graphs/contributors).

**Special thanks to**

- Thomas Watson Steen [ <mailto:w@tson.dk> / [@wa7son](http://twitter.com/wa7son) ].

## Copyright

(c) 2010-2021 GoodData Corporation
This repository is governed by the terms and conditions in the LICENSE. This repository contains a number of open source packages detailed in NOTICES, including the GoodData Ruby SDK, which is licensed under the BSD-3-Clause license and contains additional open source components detailed in the file called LICENSE_FOR_RUBY_SDK_COMPONENT.
