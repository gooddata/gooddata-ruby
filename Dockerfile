FROM harbor.intgdc.com/tools/gdc-java-8-jre:fcb7257

ARG RVM_VERSION=stable
ARG JRUBY_VERSION=9.2.5.0

LABEL image_name="GDC LCM Bricks"
LABEL maintainer="LCM <lcm@gooddata.com>"
LABEL git_repository_url="https://github.com/gooddata/gooddata-ruby/"
LABEL parent_image="harbor.intgdc.com/tools/gdc-java-8-jre:fcb7257"

# which is required by RVM
RUN yum install -y curl which patch make git maven \
    && yum clean all \
    && rm -rf /var/cache/yum

# Install + verify RVM with gpg (https://rvm.io/rvm/security)
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import - \
    && curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - \
    && curl -sSL https://get.rvm.io | bash -s ${RVM_VERSION} \
    && curl -sSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer -o rvm-installer \
    && curl -sSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc -o rvm-installer.asc \
    && gpg2 --verify rvm-installer.asc rvm-installer \
    && bash rvm-installer \
    && rm rvm-installer rvm-installer.asc \
    && echo "bundler" >> /usr/local/rvm/gemsets/global.gems \
    && echo "rvm_silence_path_mismatch_check_flag=1" >> /etc/rvmrc \
    && echo "install: --no-document" > /etc/gemrc

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]

RUN rvm install jruby-${JRUBY_VERSION} && gem update --system \
    && gem install bundler rake

WORKDIR /src

RUN groupadd -g 48 apache \
    && groupadd -g 65065 gdcshare \
    && useradd -u 48 -m --no-log-init -r -g apache -G rvm apache \
    && usermod -a -G gdcshare apache \
    && chown apache: /src

USER apache

ADD ./bin ./bin
ADD --chown=apache:apache ./ci ./ci
ADD --chown=apache:apache ./lib ./lib
ADD ./SDK_VERSION .
ADD ./VERSION .
ADD ./Gemfile .
ADD ./gooddata.gemspec .

#build redshift dependencies
RUN mvn -f ci/redshift/pom.xml clean install -P binary-packaging
RUN cp -rf ci/redshift/target/*.jar ./lib/gooddata/cloud_resources/redshift/drivers/

#build snowflake dependencies
RUN mvn -f ci/snowflake/pom.xml clean install -P binary-packaging
RUN cp -rf ci/snowflake/target/*.jar ./lib/gooddata/cloud_resources/snowflake/drivers/

#build bigquery dependencies
RUN mvn -f ci/bigquery/pom.xml clean install -P binary-packaging
RUN cp -rf ci/bigquery/target/*.jar ./lib/gooddata/cloud_resources/bigquery/drivers/

#build postgresql dependencies
RUN mvn -f ci/postgresql/pom.xml clean install -P binary-packaging
RUN cp -rf ci/postgresql/target/*.jar ./lib/gooddata/cloud_resources/postgresql/drivers/

RUN bundle install

ARG GIT_COMMIT=unspecified
ARG BRICKS_VERSION=unspecified
LABEL git_commit=$GIT_COMMIT
LABEL bricks_version=$BRICKS_VERSION

ENV GOODDATA_RUBY_COMMIT=$GIT_COMMIT

CMD [ "./bin/help.sh" ]
