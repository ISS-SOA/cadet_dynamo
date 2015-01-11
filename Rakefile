require './app'
require 'aws-sdk'
require_relative 'model/tutorial.rb'
require 'rake/testtask'
require 'config_env/rake_tasks'
ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")

task :default => :spec

# WARNING: Running tests deletes all data from the Tutorial database on DynamoDB
desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

desc "Deploy to Heroku"
task :deploy => :'config_env:heroku' do
  sh 'git push heroku master'
end

namespace :queue do
  desc "Create all queues"
  task :create do
    sqs = AWS::SQS.new(region: ENV['AWS_REGION'])

    begin
      queue = sqs.queues.create('Tutorial')
      queue = sqs.queues.create('RecentCadet')
    rescue => e
      puts "Error creating queues: #{e}"
    else
      puts "Queues created"
    end
  end
end

namespace :db do
  desc "Create all database tables"
  task :migrate => [:migrate_tutorial]

  desc "Create tutorial table"
  task :migrate_tutorial do
    begin
      Tutorial.create_table(5, 6)
      puts "Tutorial table created"
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'Tutorial table exists -- no changes made, no retry attempted'
    end
  end
end
