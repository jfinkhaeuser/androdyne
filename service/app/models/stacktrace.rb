class Stacktrace < ActiveRecord::Base
  belongs_to :package
  has_many :occurrences
  has_many :log_messages
  validates_uniqueness_of :package_id, :scope => [:version_code, :hash]
end
