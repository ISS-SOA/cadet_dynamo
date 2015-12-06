require 'dynamoid'

class Tutorial
  include Dynamoid::Document
  field :description, :string
  field :deadline, :datetime
  field :usernames, :string
  field :badges, :string
  field :completed, :string
  field :missing, :string
  field :late, :string
  field :notfound, :string

  def self.destroy(id)
    find(id).destroy
  end

  def self.delete_all
    all.each(&:delete)
  end
end
