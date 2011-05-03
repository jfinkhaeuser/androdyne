class CreateStacktraces < ActiveRecord::Migration
  def self.up
    create_table :stacktraces do |t|
      # Identifying information
      t.integer :version_code,    :null => false
      t.string  :hash,            :null => false

      # Display information
      t.string  :version,         :null => false
      t.string  :trace,           :null => false

      # Foreign key
      t.integer :package_id,      :null => false

      t.timestamps
    end

    add_index :stacktraces, ["hash"], :name => "index_stacktraces_on_hash"
    add_index :stacktraces, ["package_id", "version_code", "hash"], :name => "index_stacktraces_on_unique", :unique => true
  end

  def self.down
    drop_table :stacktraces
  end
end
