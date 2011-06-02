class LogMessage < ActiveRecord::Base
  has_and_belongs_to_many :occurrences
  validates_uniqueness_of :tag, :scope => [:message]
end
