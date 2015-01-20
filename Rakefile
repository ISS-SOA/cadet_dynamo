require 'rake/testtask'
require 'config_env/rake_tasks'

task :echo_env, [:var] => :config do |t, args|
  puts "#{args[:var]}: #{ENV[args[:var]]}"
end

desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

task :config do
  ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
end

namespace :deploy do
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
    sqs = AWS::SQS.new(region: ENV['AWS_REGION'])

    begin
      queue = sqs.queues.create('RecentCadet')
      puts "Queue created"
    rescue => e
      puts "Error creating queue: #{e}"
    end
  end
end

namespace :db do
  require_relative 'model/tutorial.rb'

  desc "Create tutorial table"
  task :migrate do
    begin
      table = Tutorial.create_table(5, 6)
      puts "Tutorial table created: #{table}"
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'Tutorial table already exists'
    end
  end
end
