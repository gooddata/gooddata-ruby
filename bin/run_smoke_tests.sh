#!/usr/bin/env bash

export LCM_BRICKS_IMAGE_TAG=$GOODDATA_RUBY_COMMIT
export GD_ENV=staging
/bin/bash -l -c ". /home/updater/.rvm/scripts/rvm && bundle exec rake -f lcm.rake test:smoke"
