require './app'
require_relative 'model/tutorial.rb'
require 'rake/testtask'

task :default => :spec

# WARNING: Running tests deletes all data from the Tutorial database on DynamoDB
desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

namespace :db do
  desc "Create database"
  task :migrate do
    begin
      Tutorial.create_table(5, 6)
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'DB exists -- no changes made, no retry attempted'
    end
  end
end
