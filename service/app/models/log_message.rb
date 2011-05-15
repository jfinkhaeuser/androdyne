class LogMessage < ActiveRecord::Base
  belongs_to :stacktrace
  validates_uniqueness_of :tag, :scope => [:message]
end
