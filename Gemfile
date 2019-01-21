source 'https://rubygems.org'

group 'development' do
  unless RUBY_PLATFORM == 'java'
    # git because https://github.com/prontolabs/pronto/issues/312
    gem 'pronto',
        git: 'https://github.com/prontolabs/pronto',
        ref: '266805b'
  end
end

# Specify your gem's dependencies in gooddata.gemspec
gemspec
