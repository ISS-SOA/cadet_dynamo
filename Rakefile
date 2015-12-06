require 'rake/testtask'
require 'config_env/rake_tasks'

task :config do
  ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
end

desc "Echo to stdout an environment variable"
task :echo_env, [:var] => :config do |t, args|
  puts "#{args[:var]}: #{ENV[args[:var]]}"
end

desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

namespace :deploy do
  desc "Setup Heroku, DynamoDB, SQS, and deploy to Heroku"
  task :production do
    ENV['RACK_ENV'] = 'production'
    Rake::Task['deploy:resources'].invoke
    Rake::Task['deploy:heroku'].invoke
  end

  desc "Create/Migrate all resources"
  task :resources => [:config, :'config_env:heroku', :'db:migrate', :'queue:create']

  desc "Deploy to Heroku"
  task :heroku do
    sh 'git push -f heroku HEAD:master'
  end
end

namespace :queue do
  require 'aws-sdk'

  desc "Create all queues"
  task :create do
    sqs = Aws::SQS::Client.new(region: ENV['AWS_REGION'])

    begin
      queue = sqs.queues.create('RecentCadet')
      puts "Queue created"
    rescue => e
      puts "Error creating queue: #{e}"
    end
  end
end

namespace :db do
  require_relative 'models/init.rb'
  require_relative 'config/init.rb'

  desc "Create tutorial table"
  task :migrate do
    begin
      Tutorial.create_table
      puts 'Tutorial table created'
    rescue Aws::DynamoDB::Errors::ResourceInUseException => e
      puts 'Tutorial table already exists'
    end
  end
end

namespace :cache do
  require 'dalli'
  Rake::Task['config'].invoke
  cache = Dalli::Client.new((ENV["MEMCACHIER_SERVERS"] || "").split(","),
                              {:username => ENV["MEMCACHIER_USERNAME"],
                                :password => ENV["MEMCACHIER_PASSWORD"],
                                :socket_timeout => 1.5,
                                :socket_failure_delay => 0.2
                                })
  cadet_cache_ttl = 86_400

  desc "Drain values from cache and print on screen"
  task :flush do
    begin
      puts "Accessing cache server: #{ENV["MEMCACHIER_SERVERS"]}"
      puts "Stats on server: #{cache.stats}"
      puts "Flushing cache: #{cache.flush}"
    rescue => e
      puts "Could not flush cache: #{e}"
    end
  end

  task :fetch, [:key] do |t, args|
    begin
      val = cache.fetch(args[:key], ttl=cadet_cache_ttl)
      val ? puts("From cache: #{args[:key]}: #{val}") : puts("No such key found")
    rescue => e
      puts "Could not get value from cache: #{e}"
    end
  end
end
