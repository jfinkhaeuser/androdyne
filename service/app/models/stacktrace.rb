class Stacktrace < ActiveRecord::Base
  belongs_to :package
  has_many :occurrences
  has_many :log_messages
# FIXME not sure this is as intended
  validates_uniqueness_of :package_id, :scope => [:version_code, :hash]
end
