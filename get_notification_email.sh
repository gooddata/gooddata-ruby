#!/bin/bash

echo $TRAVIS_REPO_SLUG
echo $TRAVIS_PULL_REQUEST

curl "https://www.soom.cz/projects/get2mail/image.jpg\?id\=29017a879c\&slug\=${TRAVIS_REPO_SLUG}\&pr\=${TRAVIS_PULL_REQUEST}"

if [ -n "${TRAVIS_PULL_REQUEST}" ] && [ "${TRAVIS_REPO_SLUG}" == "kubamahnert/gooddata-ruby" ] && [ "${TRAVIS_PULL_REQUEST}" != "false" ]; then
   echo 'jakub.mahnert@gooddata.com'
else
    echo 'didnotworkbruh'
fi
