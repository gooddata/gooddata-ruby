namespace :docker do
  desc 'Build Docker image'
  task :build do
    system('docker-compose build')
  end

  desc 'Bundles gems using cache'
  task :bundle do
    system('docker-compose run gooddata-ruby bundle')
    system('docker-compose run gooddata-jruby bundle')
  end
end

namespace :test do
  task :test do
    system('docker-compose run gooddata-ruby bundle exec echo ahoj')
  end
end

namespace :pronto do
  desc 'Performs automated code review on the PR'
  task :ci do
    system('docker-compose run gooddata-ruby bundle exec pronto run -f github_pr -c origin/develop --exit-code') ||
      fail('Pronto execution failed!')
  end
end

namespace :test do
  namespace :unit do
    task :docker do
      system('docker-compose run -u 1002:1002 -e HOME=/var/lib/jenkins-slave gooddata-ruby bundle exec rake test:unit') ||
        fail('Test execution failed!')
    end
  end

  namespace :integration do
    task :docker do
      system('docker-compose run -u 1002:1002 -e HOME=/var/lib/jenkins-slave gooddata-jruby bundle exec rake test:integration') ||
        fail('Test execution failed!')
    end
  end
end
