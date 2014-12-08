require './app'
require_relative 'model/tutorial.rb'
require 'rake/testtask'

task :default => :spec

desc "Run all tests"
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

namespace :db do
  desc "Create database"
  task :migrate do
    begin
      Tutorial.create_table(5,6, :hash_key => { :id => :number })
    rescue AWS::DynamoDB::Errors::ResourceInUseException => e
      puts 'DB exists -- no changes made, no retry attempted'
    end
  end
end
