class Stacktrace < ActiveRecord::Base
  belongs_to :package
  has_many :occurrences
  has_many :log_messages
end
