FROM ruby:3.2.1

MAINTAINER Tomas Korcak <korczis@gmail.com>

RUN apt-get update && apt-get install -y curl make gcc git openssh-client g++ python binutils-gold gnupg libstdc++6 cmake

# Switch to directory with sources
WORKDIR /src
ENV HOME=/src
ENV BUNDLE_PATH=$HOME/bundle

RUN gem update --system \
    && gem install --install-dir $BUNDLE_PATH bundler -v 2.4.6 \
    && gem install --install-dir $BUNDLE_PATH rake -v 13.0.6

# build postgresql dependencies
RUN mvn -f ci/postgresql/pom.xml clean install -P binary-packaging
RUN cp -rf ci/postgresql/target/*.jar ./lib/gooddata/cloud_resources/postgresql/drivers/

# build mssql dependencies
RUN mvn -f ci/mssql/pom.xml clean install -P binary-packaging
RUN cp -rf ci/mssql/target/*.jar ./lib/gooddata/cloud_resources/mssql/drivers/

# build mysql dependencies
RUN mvn -f ci/mysql/pom.xml clean install -P binary-packaging
RUN cp -rf ci/mysql/target/*.jar ./lib/gooddata/cloud_resources/mysql/drivers/

ADD . .

CMD ["./bin/gooddata"]
