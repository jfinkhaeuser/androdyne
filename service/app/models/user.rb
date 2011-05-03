class User < ActiveRecord::Base
  acts_as_authentic

  def to_s
    if id.nil?
      super.to_s
    else
      "<#{id}|#{login}|#{email}>"
    end
  end
end
