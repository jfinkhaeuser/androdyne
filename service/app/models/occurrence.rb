class Occurrence < ActiveRecord::Base
  belongs_to :stacktrace
#FIXME see other models
  validates_uniquness_of :phone, :scope => [:os_version]
end
