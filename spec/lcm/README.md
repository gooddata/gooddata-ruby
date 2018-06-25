# Running LCM tests

## Running tests in Docker

1. install Docker
1. run `bundle exec rake -f lcm.rake docker:build`
1. run `bundle exec rake -f lcm.rake docker:bundle` (every time you update gems)
1. run `bundle exec rake -f lcm.rake test:integration:docker`

## Running tests locally
1. switch to JRuby (because JRuby ADS driver is needed): `rvm use jruby`
1. add this line `127.0.0.1 testbucket.localstack` to `/etc/hosts`
1. add this line `127.0.0.1 localstack` to `/etc/hosts`
1. add certificates to Java `sudo keytool -importcert -alias
   gooddata-cert -file "data/new_ca.cer" -keystore
/Library/Java/JavaVirtualMachines/jdk1.8.0_144.jdk/Contents/Home/jre/lib/security/cacerts
-storepass 'changeit'` (on Fedora it looks like this: sudo keytool -importcert -alias gooddata-cert -file "data/new_ca.cer" -keystore /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.171-4.b10.fc27.x86_64/jre/lib/security/cacerts -storepass 'changeit')
1. start localstack: `bundle exec rake -f lcm.rake localstack:start`
1. run `bundle exec rake -f lcm.rake test:integration`

