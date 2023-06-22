FROM ruby:2.3-alpine

MAINTAINER Tomas Korcak <korczis@gmail.com>

RUN apk add --no-cache curl make gcc git g++ python linux-headers binutils-gold gnupg libstdc++ openssl cmake curl-dev

RUN ln -s /usr/bin/make /usr/bin/gmake

# Switch to directory with sources
WORKDIR /src
ENV HOME=/src
ENV BUNDLE_PATH=$HOME/bundle

RUN gem update --system 3.0.6 \
    && gem install --install-dir $BUNDLE_PATH bundler -v 1.17.3 \
    && gem install --install-dir $BUNDLE_PATH rake -v 11.3.0

ADD . .

CMD ["./bin/gooddata"]
