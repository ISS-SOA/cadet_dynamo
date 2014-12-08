require 'aws-sdk'

class Tutorial < AWS::Record::HashModel
  string_attr :description
  string_attr :usernames
  string_attr :badges
end
