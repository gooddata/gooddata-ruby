#!/usr/bin/env bash

export JRUBY_OPTS=-J-XX:MaxRAMPercentage=75

/bin/bash -l -c "bundle exec ./bin/run_brick.rb release_brick"
