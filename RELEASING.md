# Releasing Gooddata Gem

1. `git clone https://github.com/gooddata/gooddata-ruby.git gooddata-ruby`
1. `cd gooddata-ruby`
1. `git checkout master`
1. `rvm use ruby`
1. `bundle install`
1. bump version in [lib/gooddata/version.rb](lib/gooddata/version.rb)
1. `bundle exec rake version:bump`
1. push to master
1. `git push origin tags/{version}`
1. `rake gem:release`
1. `rvm use jruby && rm Gemfile.lock && bundle install`
1. `rake gem:release`
1. release [cookbook](https://github.com/gooddata/gooddata-ruby-examples)
