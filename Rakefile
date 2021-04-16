# encoding: UTF-8

require 'rubygems'

require 'bundler/setup'
require 'bundler/cli'
require 'bundler/gem_tasks'
require 'gooddata'
require 'rake/testtask'
require 'rspec/core/rake_task'

require 'yaml'
require 'yard'

require 'rubocop/rake_task'

desc 'Run RuboCop'
RuboCop::RakeTask.new(:cop) do |task|
  task.patterns = ['{lib,spec}/**/*.rb']
  task.options = ['--force-exclusion']
end

desc 'Run continuous integration test'
task :ci do
  Rake::Task['test:unit'].invoke
  unless ENV['TRAVIS'] == 'true' && ENV['TRAVIS_SECURE_ENV_VARS'] == 'false'
    Rake::Task['test:integration'].invoke
  end
  Rake::Task['test:cop'].invoke
end

namespace :gem do
  desc "Release gem version #{GoodData::VERSION} to rubygems"
  task :release do
    gem = "gooddata-#{GoodData::VERSION}.gem"
    origin_license_file = 'LICENSE'
    new_license_file = 'LICENSE_FOR_RUBY_SDK_COMPONENT.txt'
    notices_file = 'NOTICES.txt'
    File.delete(origin_license_file) if File.exist?(origin_license_file)
    File.delete(notices_file) if File.exist?(notices_file)
    puts "Deleted files: #{origin_license_file} and #{notices_file}"
    File.rename(new_license_file, origin_license_file) if File.exists?(new_license_file)
    puts "Renamed file #{new_license_file} to #{origin_license_file}"
    puts "Building #{gem} ..."
    res = `gem build ./gooddata.gemspec`
    file = res.match('File: (.*)')[1]
    next unless file

    puts "Pushing #{file} ..."
    system("gem push #{file}")
  end
end

namespace :hook do
  hook_path = File.join(File.dirname(__FILE__), '.git', 'hooks', 'pre-commit').to_s

  desc 'Installs git pre-commit hook running rubocop'
  task :install do
    if File.exist?(hook_path)
      puts 'Git pre-commit hook is already installed'
    else
      File.open(hook_path, 'w') do |file|
        file.write("#! /usr/bin/env bash\n")
        file.write("\n")
        file.write("rake cop\n")
      end
      system "chmod 755 #{hook_path}"
      puts 'Git commit hook was installed'
    end
  end

  desc 'Uninstalls git pre-commit hook'
  task :uninstall do
    res = File.exist?(hook_path)
    if res
      puts 'Uninstalling git pre-commit hook'
      system "rm #{hook_path}"
      puts 'Git pre-commit hook was uninstalled'
    else
      puts 'Git pre-commit hook is not installed'
    end
  end

  desc 'Checks if is git pre-commit hook installed'
  task :check do
    res = File.exist?(hook_path)
    if res
      puts 'Git pre-commit IS installed'
    else
      puts 'Git pre-commit IS NOT installed'
    end
  end
end

namespace :license do
  desc 'Show license report'
  task :info do
    Bundler::CLI.start(['exec', 'license_finder', '--decisions-file', 'dependency_decisions.yml'])
  end

  desc 'Generate licenses report - DEPENDENCIES.md'
  task :report do
    `bundle exec license_finder report --decisions-file dependency_decisions.yml --format=markdown > DEPENDENCIES.md`
  end

  desc 'Check if DEPENDENCIES.md is up to date'
  task :check do
    Rake::Task['license:report'].invoke
    res = `git diff --stat DEPENDENCIES.md`
    fail 'License check error' unless res.include?('1 file changed, 1 insertion(+), 1 deletion(-)')

    puts 'All licenses seem to be OK'
  end

  desc 'Add license header to each file'
  task :add do
    spec = Gem::Specification.load('gooddata.gemspec')
    license = File.readlines(File.expand_path('../LICENSE.rb', __FILE__))
    license << "\n"
    license_lines = license.length

    spec.files.each do |path|
      next if path == 'LICENSE.rb'
      next unless path.end_with?('.rb')

      puts "Processing #{path}"

      content = File.read(path)
      content_lines = content.lines

      update = content_lines.length < license_lines

      if update == false
        content_with_license = (license + content_lines[license_lines..-1]).join
        update = content != content_with_license
      end

      next unless update

      puts "Updating #{path}"

      if content_lines.length > 0 && content_lines[0].downcase.strip == '# encoding: utf-8'
        content_lines.slice!(0)
        content_lines.slice!(0) if content_lines[0] == "\n"
      end

      new_content = (license + content_lines).join
      File.open(path, 'w') { |file| file.write(new_content) }
    end
  end
end

# Updates the changelog with commit messages
def update_changelog(new_version)
  changelog = headless_changelog
  fail 'the version is already mentioned in the changelog' if changelog =~ /## #{new_version}/
  puts "Creating changelog for version #{new_version}"
  File.open('CHANGELOG.md', 'w+') do |file|
    file.puts changelog_header + "\n"
    file.puts "## #{new_version}"
    changes(changelog).each { |change| file.puts ' - ' + change }
    file.puts changelog
  end
end

def changes(changelog)
  current_commit = `git rev-parse HEAD`.chomp
  last_release = changelog.split("\n").reject(&:empty?).first.delete('## ').chomp
  last_release_commit = `git rev-parse #{last_release}`.chomp
  `git log --format=%s --no-merges #{last_release_commit}..#{current_commit}`.split("\n").reject(&:empty?)
end

def headless_changelog
  changelog = File.read('CHANGELOG.md')
  changelog.slice! changelog_header
  changelog
end

def changelog_header
  '# GoodData Ruby SDK Changelog'
end

namespace :version do
  desc 'Updates the changelog, commits and tags the bump'
  task :bump do
    require_relative 'lib/gooddata/version'
    new_version = GoodData::VERSION
    update_changelog(new_version)
    `git add CHANGELOG.md SDK_VERSION`
    `git commit -m "Bump version to #{new_version}"`
    `git tag #{new_version}`
  end

  desc 'Shows changes since last release'
  task :changelog do
    puts changes(headless_changelog)
  end
end

RSpec::Core::RakeTask.new(:test)

namespace :test do
  desc 'Run unit tests'
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*.rb'
  end

  desc 'Run integration tests'
  RSpec::Core::RakeTask.new(:sdk) do |t|
    t.pattern = 'spec/integration/**/*.rb'
    t.rspec_opts = '--color --format documentation --require spec_helper \
    --format RspecJunitFormatter --out integration.results.xml'
  end

  desc 'Run LCM tests'
  RSpec::Core::RakeTask.new(:lcm) do |t|
    t.pattern = 'spec/lcm/integration/**/*.rb'
  end

  desc 'Run project-related tests. Separated from test:sdk so that ' \
       'it is possible to save time by running the tasks in parallel.'
  RSpec::Core::RakeTask.new(:project) do |t|
    t.pattern = 'spec/project/**/*.rb'
    t.rspec_opts = '--color --format documentation --require spec_helper \
    --format RspecJunitFormatter --out project.results.xml'
  end

  desc 'Run coding style tests'
  RSpec::Core::RakeTask.new(:cop) do
    Rake::Task['cop'].invoke
  end

  task :all => [:unit, :integration, :cop, :lcm, :project]
  task :ci => [:unit, :integration, :lcm, :project]
  task :integration => [:sdk, :project]
end

desc 'Run all tests'
task :test => 'test:all'

task :usage do
  puts 'No rake task specified, use rake -T to list them'
end

YARD::Rake::YardocTask.new

task :default => [:usage]

namespace :gitflow do
  task :init do
    file_path = File.join(File.dirname(__FILE__), 'bin/gitflow-init.sh')
    system(file_path) || fail('Initializing git-flow failed!')
  end
end

desc 'Rotates the password of the test domain admin'
namespace :password do
  task :rotate, [:value, :encryption_key] do |_, args|
    key = 'password'
    value = args[:value]
    encryption_key = args[:encryption_key]
    encrypted_value = GoodData::Helpers.encrypt(value, encryption_key).strip
    secrets_path = File.join(File.dirname(__FILE__), 'spec/environment/secrets.yaml')
    secrets = YAML.load_file(secrets_path)
    secrets.each_value do |env|
      env[key].replace(encrypted_value) if env.key?(key)
    end
    File.write(secrets_path, secrets.to_yaml)
  end
end
