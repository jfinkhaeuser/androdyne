# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

def do_seeding
  if ENV['RAILS_ENV'] == "test"
    # These seeds apply only to the test environment.
    User.create([
      { :login => 'test', :email => 'test@test.org', :password => 'test123', :password_confirmation => 'test123' },
      { :login => 'foobar', :email => 'foo@bar.org', :password => '123test', :password_confirmation => '123test' },
    ])

  end
end
