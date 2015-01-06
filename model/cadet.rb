require 'aws-sdk'
require 'json'

class Cadet < AWS::Record::HashModel
  string_attr :username
  string_attr :badges
  timestamps

  def self.destroy(id)
    find(id).delete
  end

  def self.delete_all
    all.each { |r| r.delete }
  end
end
