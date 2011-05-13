# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

def do_seeding
  # These seeds apply only to the test environment.
  if ENV['RAILS_ENV'] == "test"
    # Create test users
    User.create([
      { :login => 'test', :email => 'test@test.org', :password => 'test123', :password_confirmation => 'test123' },
      { :login => 'foobar', :email => 'foo@bar.org', :password => '123test', :password_confirmation => '123test' },
    ])

    user = User.where(:login => 'test')[0]

    # Create test packages
    Package.create([
      { :user => user, :package_id => "com.test.app", :name => "Test App" },
    ])
  end
end

# Regular rails functionality
if File.basename($0) == "rake"
  do_seeding
end
