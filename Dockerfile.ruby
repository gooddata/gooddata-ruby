FROM ruby:2.3-alpine

MAINTAINER Tomas Korcak <korczis@gmail.com>

RUN apk add --no-cache curl make gcc git g++ python linux-headers binutils-gold gnupg libstdc++ openssl

# Switch to directory with sources
WORKDIR /src

# Copy required stuff
ADD . .

RUN gem update --system \
    && gem install bundler \
    && bundle install

ENTRYPOINT ["bundle", "exec"]

CMD ["./bin/gooddata"]
