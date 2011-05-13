class Occurrence < ActiveRecord::Base
  belongs_to :stacktrace
#FIXME see other models
  validates_uniqueness_of :phone, :scope => [:os_version]
end
