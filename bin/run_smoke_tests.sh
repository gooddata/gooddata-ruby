#!/usr/bin/env bash

export LCM_BRICKS_IMAGE_TAG=$GOODDATA_RUBY_COMMIT
export GD_ENV=staging

# WORKAROUND: temp HOME is needed since RSpec uses simplecov which requires HOME to be set to something else than '/'
# which is default when running container as the non existing user within the image.
# The core problem there is jruby's `isAbsoluteHome` method considering path of length 1 not to be absolute
/bin/bash -l -c "if [[ $HOME == '/' ]]; then export HOME=$(mktemp -d); fi && bundle exec rake -f lcm.rake test:smoke"
