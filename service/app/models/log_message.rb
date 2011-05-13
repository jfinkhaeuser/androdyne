class LogMessage < ActiveRecord::Base
  belongs_to :stacktrace
#FIXME
  validates_uniqueness_of :tag, :scope => [:message]
end
