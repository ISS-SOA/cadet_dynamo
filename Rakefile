require './app'
require_relative 'model/tutorial.rb'
require_relative 'model/cadet.rb'
require 'rake/testtask'

task :default => :spec

# WARNING: Running tests deletes all data from the Tutorial database on DynamoDB
desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

namespace :db do
  desc "Create all database tables"
  task :migrate => [:migrate_tutorial, :migrate_cadet]

  desc "Create tutorial table"
  task :migrate_tutorial do
    begin
      Tutorial.create_table(5, 6)
      puts "Tutorial table created"
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'Tutorial table exists -- no changes made, no retry attempted'
    end
  end

  desc "Create cadet table"
  task :migrate_cadet do
    begin
      Cadet.create_table(5,6)
      puts "Cadet table created"
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'Cadet table exists -- no changes made, no retry attempted'
    end
  end
end
