require 'aws-sdk'
require 'json'

class Tutorial < AWS::Record::HashModel
  string_attr :description
  date_attr :deadline
  string_attr :usernames
  string_attr :badges
  string_attr :completed
  string_attr :missing
  string_attr :late
  string_attr :notfound
  timestamps

  def self.destroy(id)
    find(id).delete
  end

  def self.delete_all
    all.each(&:delete)
  end
end
