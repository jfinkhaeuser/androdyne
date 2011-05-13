class User < ActiveRecord::Base
  acts_as_authentic
  has_many :packages
  validates_uniqueness_of :login, :email, :persistence_token

  def to_s
    if id.nil?
      super.to_s
    else
      "<#{id}|#{login}|#{email}>"
    end
  end
end
