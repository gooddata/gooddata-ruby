#!/usr/bin/env bash

export JRUBY_OPTS=-J-Xmx2560m

/bin/bash -l -c "bundle exec ./bin/run_brick.rb rollout_brick"
