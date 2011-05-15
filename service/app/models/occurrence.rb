class Occurrence < ActiveRecord::Base
  belongs_to :stacktrace
  validates_uniqueness_of :phone, :scope => [:stacktrace_id, :os_version]
end
