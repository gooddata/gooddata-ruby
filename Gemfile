source 'https://rubygems.org'

gem 'net-smtp', require: false

group 'development' do
  unless RUBY_PLATFORM == 'java'
    gem 'pronto-flay',
        git: 'https://github.com/prontolabs/pronto-flay'
        # branch: 'flay-mass-threshold'
  end
end

# Specify your gem's dependencies in gooddata.gemspec
gemspec

