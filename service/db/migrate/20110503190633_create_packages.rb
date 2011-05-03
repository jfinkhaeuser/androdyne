class CreatePackages < ActiveRecord::Migration
  def self.up
    create_table :packages do |t|
      t.string :package_id,       :null => false
      t.string :name,             :null => false
      t.string :secret,           :null => false

      # Foreign key
      t.integer :user_id,         :null => false

      t.timestamps
    end

    add_index :packages, ["package_id"], :name => "index_packages_on_package_id", :unique => true
  end

  def self.down
    drop_table :packages
  end
end
