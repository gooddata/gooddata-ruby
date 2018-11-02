FROM ruby:2.3-alpine

MAINTAINER Tomas Korcak <korczis@gmail.com>

RUN apk add --no-cache curl make gcc git g++ python linux-headers binutils-gold gnupg libstdc++ openssl cmake curl-dev

RUN ln -s /usr/bin/make /usr/bin/gmake

# Switch to directory with sources
WORKDIR /src

RUN gem update --system \
    && gem install bundler

ENV BUNDLE_PATH=/bundle

ADD . .

CMD ["./bin/gooddata"]
