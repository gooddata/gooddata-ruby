# Releasing Gooddata Gem

1. `git clone https://github.com/gooddata/gooddata-ruby.git gooddata-ruby`
1. `cd gooddata-ruby`
1. `git checkout master`
1. optionally check what's changed since last release: `bundle exec rake version:changelog`
1. bump version in [SDK_VERSION](SDK_VERSION)
1. `bundle exec rake version:bump`
1. create PR to `upstream/develop` and have it merged
1. `git push origin tags/{version}`
1. once all tests are passing, merge `develop` to `master` and the gem will be released automatically
1. release [cookbook](https://github.com/gooddata/gooddata-ruby-doc)
