#!/usr/bin/env bash

export JRUBY_OPTS="-J-XX:MaxRAMPercentage=75 -J-Djruby.nio.unsafe=true"

/bin/bash -l -c "bundle exec ./bin/run_brick.rb release_brick"
