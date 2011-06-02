class Occurrence < ActiveRecord::Base
  belongs_to :stacktrace
  has_and_belongs_to_many :log_messages
  validates_uniqueness_of :phone, :scope => [:stacktrace_id, :os_version]
end
