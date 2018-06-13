require 'pp'
require 'fileutils'
require 'pathname'
require 'rspec/core/rake_task'

# Schema for new Bricks.
brick_info_schema = {
  "type" => "object",
  "required" => ["name","version","language","created"],
  "properties" => {
    "name" => {"type" => "string"},
    "author" => {
        "type" => "object",
        "properties" => {
          "name" => {"type" => "string"},
          "email" => {"type" => "string"}
        }
    },
    "created" => {"type" => "string"},
    "version" => {"type" => "string"},
    "category" => {"type" => "string"},
    "language" => {"type" => "string"},
    "description" => { "type" => "string"},
    "tags" => {"type" => "string"},
    "is_live" => {"type" => "boolean"},
    "parameters" => {
        "type" => "array",
        "properties" => {
          "name" => {"type" => "string"},
          "description" => {"type" => "string"},
          "type" => {"type" => "string"},
          "mandatory" => {"type" => "boolean"},
        }
    }
  },
}

check_exit_code = <<-EOT
docker-compose --file=docker-compose.lcm.yml ps -q | xargs docker inspect -f '{{ .State.ExitCode }}' | while read code; do
  if [ "$code" == "1" ]; then
    exit -1
  fi
done
EOT

desc 'Gets info.json from /apps/ and validates.'
task :default do
  require 'json-schema'

  root = Pathname(__FILE__).expand_path.dirname
  bricks_root = root + "./apps/*/info.json"

  production_bricks = []
  bricks = Dir.glob(bricks_root).map do |path|
    brick = JSON.parse(File.read(path))
    if JSON::Validator.validate!(brick_info_schema, brick)
      production_bricks << brick
    else
      fail JSON::Schema::ValidationError
    end
  end

  task(:write).invoke(production_bricks)
end

desc 'Writes JSON file to location.'
task :write, :file do |w, bricks|
  require 'json'

  File.open("./build/bricks.json", 'w') do |f|
    f.puts bricks.file.to_json
  end
end

RSpec::Core::RakeTask.new(:test)
namespace :test do
  desc 'Run integration tests'
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/lcm/integration/**/*.rb'
  end

  desc 'Run load tests'
  RSpec::Core::RakeTask.new(:load) do |t|
    t.pattern = 'spec/lcm/load/**/*.rb'
  end

  desc 'Run slow tests'
  RSpec::Core::RakeTask.new(:slow) do |t|
    t.pattern = 'spec/lcm/slow/**/*.rb'
  end

  namespace :integration do
    desc 'Run integration tests in Docker'
    task :docker do
      system("docker-compose -f docker-compose.lcm.yml up --no-recreate --remove-orphans --abort-on-container-exit appstore localstack")

      # TODO: use exit-code-from after update to docker-compose >= 1.12
      # system('docker-compose up --exit-code-from appstore') ||
      #   fail('Test execution failed')
      system(check_exit_code) || fail('Test execution failed!')
    end
  end
  namespace :load do
    desc 'Run load tests in Docker'
    task :docker do
      system("docker-compose -f docker-compose.lcm.yml run --rm --remove-orphans --abort-on-container-exit appstore bundle exec rake test:load")

      system(check_exit_code) || fail('Test execution failed!')
    end
  end
end

namespace :localstack do
  desc 'Run localstack'
  task :start do
    system('docker run -it --rm  -e "SERVICES=s3:4572" -p 4572:4572 -p 8080:8080 localstack/localstack:0.8.1')
  end
end

namespace :docker do
  desc 'Build Docker image'
  task :build do
    system('docker build -f Dockerfile.jruby -t gooddata/appstore .')
  end

  desc 'Bundles gems using cache'
  task :bundle do
    system('docker-compose -f docker-compose.lcm.yml run appstore bundle')
  end
end

namespace :sdk do
  desc 'Updates gooddata-ruby to the version specified in the root Gemfile'
  task :update do
    directories = %w(.
                     ./apps/release_brick
                     ./apps/provisioning_brick
                     ./apps/rollout_brick
                     ./apps/generic_lifecycle_brick
                     ./apps/users_brick
                     ./apps/user_filters_brick)
    directories.map! { |d| File.expand_path(d) }
    root_gemfile = directories.first + '/Gemfile'
    new_ref = File.readlines(root_gemfile)
                  .find { |line| line.include?("gem 'gooddata'") }
    directories.each do |d|
      gemfile_path = d + '/Gemfile'
      new_lines = File.readlines(gemfile_path).map do |line|
        line.include?("gem 'gooddata'") ? new_ref : line
      end
      File.write(gemfile_path, new_lines.join)
      Dir.chdir(d) { Bundler.with_clean_env { system('bundle install') || raise } }
    end
    to_commit = directories.map { |d| "#{d}/Gemfile #{d}/Gemfile.lock" }
                           .join(' ')
    new_ref = new_ref.split(',').last.strip.scan(/'([\w,\.]+)'/).flatten.first
    system("git commit #{to_commit} -m 'Update gooddata-ruby #{new_ref}'") || raise
  end

  def gdruby_version_from_gemfile
    new_ref = File.readlines('Gemfile')
    .find { |line| line.include?("gem 'gooddata'") }
    new_ref.split(',').last.strip.scan(/'([\w,\.]+)'/).flatten.first
  end

  def cmd cmdname, *args, &block
    require 'open3'
    begin
      puts "running $ #{([cmdname] + args).join(' ')}"
      stdin, stdout, stderr, wait_thr = Open3.popen3(cmdname, *args)
      so = stdout.gets(nil)
      stderr.gets(nil)
      exit_code = wait_thr.value
      if block
        block.call(exit_code.exitstatus.to_i == 0, so.nil? ? '' : so)
      else
        so
      end
    rescue => e
      p "Error running $ #{([cmdname] + args).join(' ')}"
      pp e
      block.call(false, '')
    ensure
      stdin.close
      stdout.close
      stderr.close
    end
  end

  desc 'Synchronizes changelogs with gooddata-ruby'
  task :changelog, [:new_appstore_version] do |t, args|
    new_appstore_version = args[:new_appstore_version]

    last_vers = '0.0.0'
    cmd 'git', 'tag' do |ok, res|
      if ok
        res.lines.each do |line|
          line.strip!
          if line =~ /^[0-9]+\.[0-9]+\.[0-9]+(-rc[0-9]+)?.*$/
            first = line.split(/[^\d]+/)
            second = last_vers.split(/[^\d]+/)
            (0..[first.length, second.length].max-1).each_with_index do |val, index|
              if first[index].to_i > second[index].to_i
                last_vers = line
                break
              elsif second[index].to_i > first[index].to_i
                break
              end
            end
          end
        end
      end
    end

    last_tag_hash = cmd 'git', 'rev-parse', last_vers
    puts "Lastest AppStore tag is #{last_vers}, #{last_tag_hash}"

    possible_gdruby_version_from_log = cmd 'git', 'log', last_vers do |ok, res|
      shortid = []
      if ok
        res.lines.each do |line|
          if line =~ /^commit [0-9a-z]+/
            commit = line.split[1]
          elsif line =~ /^    Update gooddata-ruby [0-9a-z]+/
            shortid << line.split[2]
          end
        end
      end
      shortid
    end

    if gdruby_version_from_gemfile == possible_gdruby_version_from_log.first
      gdruby_version_from_log = possible_gdruby_version_from_log[1]
    else
      gdruby_version_from_log = possible_gdruby_version_from_log.first
    end
    puts "Short id of gooddata-ruby from Gemfile #{gdruby_version_from_gemfile}"
    puts "Second latest gooddata-ruby commit short id #{gdruby_version_from_log}"

    cmd 'git', 'remote', 'add', 'gdcrb', 'https://github.com/gooddata/gooddata-ruby.git'
    cmd 'git', 'fetch', '--all'
    File.open('CHANGELOG.md', 'r') do |origfile|
      File.unlink('CHANGELOG.md')
      newsection = false
      File.open('CHANGELOG.md', 'w') do |file|
        file.write("# GoodData AppStore Changelog, changes from gooddata-ruby\n\n")
        file.write("## AppStore #{new_appstore_version}\n")
        cmd 'git', 'log', '--no-merges', "#{gdruby_version_from_log}..#{gdruby_version_from_gemfile}" do |ok, out|
          if ok
            out.lines.each do |gitline|
              if gitline =~/^commit [0-9a-z]+$/ and not newsection
                newsection = true
                next
              elsif gitline =~ /^    .+$/ and newsection
                file.write("- " + gitline.strip + "\n")
                newsection = false
              end
            end
          end
        end
        file.write origfile.drop(1).join('')
      end
    end

    cmd 'git', 'add', 'CHANGELOG.md'
  end
end

desc 'Releases new AppStore version. Uses version passed as an argument. \
      Otherwise increments patch version.'
task :release, [:version] do |t, args|
  new_appstore_version = args[:version]
  if new_appstore_version.nil?
    new_appstore_version = File.open('VERSION').read().strip
    version = new_appstore_version.split('.')
    version[2] = (version[2].to_i + 1).to_s
    new_appstore_version = version.join('.')
  end

  File.open('VERSION', 'w+t') {|file| file.write(new_appstore_version + "\n")}
  cmd 'git', 'add', 'VERSION'

  Rake::Task["sdk:changelog"].invoke(new_appstore_version)
  cmd 'git', 'commit', '-m', "Bump version to #{new_appstore_version}"

  cmd 'git', 'tag', "#{new_appstore_version}"
  # cmd 'git', 'push', 'gerrit', "#{new_appstore_version}"
end
