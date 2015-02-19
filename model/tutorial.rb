require 'aws-sdk'
require 'json'

class Tutorial < AWS::Record::HashModel
  string_attr :description
  string_attr :deadline
  string_attr :usernames
  string_attr :badges
  string_attr :completed
  string_attr :missing
  timestamps

  def self.destroy(id)
    find(id).delete
  end

  def self.delete_all
    all.each { |r| r.delete }
  end
end
