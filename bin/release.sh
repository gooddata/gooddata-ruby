#!/usr/bin/env bash

export JRUBY_OPTS="-J-XX:MaxRAMPercentage=75 -J-Djdk.tls.client.protocols=TLSv1.2 -J-Dhttps.protocols=TLSv1.2"

/bin/bash -l -c "bundle exec ./bin/run_brick.rb release_brick"
