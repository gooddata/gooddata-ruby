#!/usr/bin/env bash

git flow init -d -f
git config gitflow.branch.production "release"
git config gitflow.prefix.feature "feature-"
git config gitflow.prefix.release "release-"
git config gitflow.prefix.hotfix "hotfix-"
git config gitflow.prefix.support "support-"
