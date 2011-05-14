class Package < ActiveRecord::Base
  belongs_to :user
  has_many :stacktraces
  validates_uniqueness_of :package_id
  before_create :generate_secret

private
  def generate_secret
    # When creating Package objects, generate the secret
    if not self.secret or 0 == self.secret.length
      self.secret = SecureRandom.base64(30)
    end
  end
end
