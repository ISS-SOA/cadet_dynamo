require 'aws-sdk'

class Tutorial < AWS::Record::HashModel
  # integer_attr :id
  string_attr :description
  string_attr :usernames
  string_attr :badges
  timestamps

  def self.destroy(id)
    find(id).delete
  end

  def self.delete_all
    all.each { |r| r.delete }
  end
end
